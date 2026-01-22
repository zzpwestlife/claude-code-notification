/**
 * 飞书通知脚本 - 手环震动提醒版
 * 通过飞书webhook发送消息，触发手机通知并同步到手环震动提醒
 */

require('dotenv').config();
const https = require('https');
const http = require('http');
const { execSync } = require('child_process');
const path = require('path');
const os = require('os');

/**
 * 获取Git仓库信息
 * @returns {Object} Git信息对象
 */
function getGitInfo() {
    try {
        const gitRoot = execSync('git rev-parse --show-toplevel', { encoding: 'utf-8' }).trim();
        const branch = execSync('git rev-parse --abbrev-ref HEAD', { encoding: 'utf-8' }).trim();
        const commitHash = execSync('git rev-parse --short HEAD', { encoding: 'utf-8' }).trim();
        const commitMessage = execSync('git log -1 --pretty=%s', { encoding: 'utf-8' }).trim();
        const commitAuthor = execSync('git log -1 --pretty=%an', { encoding: 'utf-8' }).trim();
        const commitTime = execSync('git log -1 --pretty=%ci', { encoding: 'utf-8' }).trim().split(' ')[0];

        // 检查是否有未提交的更改
        let status = '';
        try {
            const statusOutput = execSync('git status --porcelain', { encoding: 'utf-8' });
            if (statusOutput.trim()) {
                const lines = statusOutput.trim().split('\n');
                const modified = lines.filter(l => l.match(/^ M/)).length;
                const added = lines.filter(l => l.match(/^\?\?/)).length;
                const staged = lines.filter(l => l.match(/^M/)).length;

                const parts = [];
                if (modified > 0) parts.push(`${modified} 个修改`);
                if (staged > 0) parts.push(`${staged} 个暂存`);
                if (added > 0) parts.push(`${added} 个未跟踪`);
                status = parts.join(', ');
            }
        } catch (e) {
            // 忽略错误
        }

        // 检查是否有未推送的提交
        let unpushed = '';
        try {
            const unpushedCount = execSync(`git log @{u}..HEAD --oneline | wc -l`, { encoding: 'utf-8' }).trim();
            if (parseInt(unpushedCount) > 0) {
                unpushed = `有 ${unpushedCount} 个未推送提交`;
            }
        } catch (e) {
            // 可能没有上游分支，忽略错误
        }

        return {
            root: gitRoot,
            projectName: path.basename(gitRoot),
            branch,
            commitHash,
            commitMessage,
            commitAuthor,
            commitTime,
            status,
            unpushed
        };
    } catch (error) {
        return null;
    }
}

/**
 * 飞书webhook通知类
 */
class FeishuNotifier {
    /**
     * 构造函数
     * @param {string} webhookUrl - 飞书机器人的webhook地址
     */
    constructor(webhookUrl) {
        this.webhookUrl = webhookUrl;
    }

    /**
     * 发送文本消息到飞书
     * @param {string} message - 消息内容
     * @param {Object} options - 额外选项
     * @returns {Promise<boolean>} 发送是否成功
     */
    async sendText(message, options = {}) {
        const payload = {
            msg_type: "text",
            content: {
                text: message
            }
        };

        return this._sendPayload(payload);
    }

    /**
     * 解析markdown并转换为飞书富文本结构
     * @param {string} content - markdown格式的内容
     * @returns {Array} 飞书富文本元素数组
     */
    _parseMarkdownToFeishu(content) {
        const elements = [];
        let remaining = content;

        while (remaining.length > 0) {
            // 处理加粗 **text** - 飞书不支持直接加粗，直接输出文本
            const boldMatch = remaining.match(/^(\*\*)(.+?)\*\*/);
            if (boldMatch) {
                elements.push({ tag: "text", text: boldMatch[2] });
                remaining = remaining.slice(boldMatch[0].length);
                continue;
            }

            // 处理行内代码 `code` - 飞书不支持，直接输出文本
            const codeMatch = remaining.match(/^`([^`]+)`/);
            if (codeMatch) {
                elements.push({ tag: "text", text: codeMatch[1] });
                remaining = remaining.slice(codeMatch[0].length);
                continue;
            }

            // 处理普通文本（直到下一个特殊标记或结束）
            const nextBold = remaining.indexOf('**');
            const nextCode = remaining.indexOf('`');
            let endIndex = remaining.length;

            if (nextBold !== -1 && nextBold < endIndex) endIndex = nextBold;
            if (nextCode !== -1 && nextCode < endIndex) endIndex = nextCode;

            if (endIndex > 0) {
                const text = remaining.slice(0, endIndex);
                if (text) {
                    elements.push({ tag: "text", text: text });
                }
                remaining = remaining.slice(endIndex);
            }
        }

        return elements;
    }

    /**
     * 发送富文本消息到飞书
     * @param {string} title - 消息标题
     * @param {string} content - 消息内容（支持markdown格式）
     * @returns {Promise<boolean>} 发送是否成功
     */
    async sendRichText(title, content) {
        // 按行分割内容
        const lines = content.split('\n');
        const postContent = [];

        for (const line of lines) {
            // 跳过空行
            if (line.trim() === '') {
                continue;
            }
            // 解析每行的markdown
            const elements = this._parseMarkdownToFeishu(line);
            if (elements.length > 0) {
                postContent.push(elements);
            }
        }

        const payload = {
            msg_type: "post",
            content: {
                post: {
                    zh_cn: {
                        title: title,
                        content: postContent
                    }
                }
            }
        };

        return this._sendPayload(payload);
    }

    /**
     * 发送交互式卡片消息
     * @param {string} title - 卡片标题
     * @param {string} content - 卡片内容
     * @returns {Promise<boolean>} 发送是否成功
     */
    async sendCard(title, content) {
        const payload = {
            msg_type: "interactive",
            content: {
                type: "template",
                data: {
                    template_id: "AAqKGP7Qx6y9R",
                    template_variable: {
                        title: title,
                        content: content
                    }
                }
            }
        };

        return this._sendPayload(payload);
    }

    /**
     * 发送HTTP请求到飞书webhook
     * @param {Object} payload - 请求载荷
     * @returns {Promise<boolean>} 发送是否成功
     */
    _sendPayload(payload) {
        return new Promise((resolve, reject) => {
            const data = JSON.stringify(payload);
            const url = new URL(this.webhookUrl);

            const options = {
                hostname: url.hostname,
                path: url.pathname + url.search,
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Content-Length': Buffer.byteLength(data)
                }
            };

            const protocol = url.protocol === 'https:' ? https : http;

            const req = protocol.request(options, (res) => {
                let responseData = '';

                res.on('data', (chunk) => {
                    responseData += chunk;
                });

                res.on('end', () => {
                    try {
                        const result = JSON.parse(responseData);
                        if (result.code === 0) {
                            console.log('✅ 飞书通知发送成功');
                            resolve(true);
                        } else {
                            console.error('❌ 飞书通知发送失败:', result.msg);
                            resolve(false);
                        }
                    } catch (error) {
                        console.error('❌ 解析飞书响应失败:', error.message);
                        resolve(false);
                    }
                });
            });

            req.on('error', (error) => {
                console.error('❌ 发送飞书请求失败:', error.message);
                resolve(false);
            });

            req.write(data);
            req.end();
        });
    }
}

/**
 * 格式化时长
 * @param {number} milliseconds - 毫秒数
 * @returns {string} 格式化的时长字符串
 */
function formatDuration(milliseconds) {
    if (!milliseconds || milliseconds < 0) return '未知';

    const seconds = Math.floor(milliseconds / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);

    if (hours > 0) {
        return `${hours}小时${minutes % 60}分${seconds % 60}秒`;
    } else if (minutes > 0) {
        return `${minutes}分${seconds % 60}秒`;
    } else {
        return `${seconds}秒`;
    }
}

/**
 * 任务完成通知函数
 * @param {string} taskInfo - 任务信息
 * @param {string} webhookUrl - 飞书webhook地址
 * @param {string} projectName - 项目名称
 * @param {Object} options - 额外选项
 * @param {string} options.title - 自定义标题（覆盖默认的"项目名: 任务信息"）
 * @param {string} options.status - 任务状态 (success/error/warning)
 * @param {string} options.description - 任务详细描述
 * @param {Date|number|string} options.startTime - 任务开始时间（Date对象、时间戳或ISO字符串）
 * @param {Object} options.tokens - Token消耗信息 {input: number, output: number, total: number}
 */
async function notifyTaskCompletion(taskInfo = "Claude Code 任务已完成", webhookUrl = null, projectName = "", options = {}) {
    // 从环境变量或配置文件读取webhook地址
    const FEISHU_WEBHOOK_URL = webhookUrl ||
                             process.env.FEISHU_WEBHOOK_URL ||
                             'https://open.feishu.cn/open-apis/bot/v2/hook/YOUR_WEBHOOK_URL_HERE';

    if (!FEISHU_WEBHOOK_URL || FEISHU_WEBHOOK_URL.includes('YOUR_WEBHOOK_URL_HERE')) {
        console.log('⚠️  请先配置飞书webhook地址');
        console.log('📝 配置方法：');
        console.log('1. 在飞书中创建群组');
        console.log('2. 添加自定义机器人');
        console.log('3. 复制webhook地址');
        console.log('4. 设置环境变量 FEISHU_WEBHOOK_URL 或修改脚本中的地址');
        return false;
    }

    const notifier = new FeishuNotifier(FEISHU_WEBHOOK_URL);

    // 获取Git信息
    const gitInfo = getGitInfo();
    const actualProjectName = projectName || (gitInfo?.projectName) || path.basename(process.cwd());

    // 计算执行时长
    const endTime = Date.now();
    let duration = null;
    let startTimeStr = '';

    if (options.startTime) {
        let startTime;
        if (options.startTime instanceof Date) {
            startTime = options.startTime.getTime();
        } else if (typeof options.startTime === 'number') {
            startTime = options.startTime;
        } else if (typeof options.startTime === 'string') {
            startTime = new Date(options.startTime).getTime();
        }
        duration = endTime - startTime;
        startTimeStr = new Date(startTime).toLocaleString('zh-CN');
    }

    // 构造丰富的通知内容
    const timestamp = new Date().toLocaleString('zh-CN');

    // 状态图标
    const statusIcon = options.status === 'error' ? '❌' : options.status === 'warning' ? '⚠️' : '✅';

    // 使用自定义标题或默认的"项目名: 任务信息"
    const title = options.title || `${actualProjectName}: ${taskInfo}`;

    // 构建富文本内容
    const rawPrompt = options.promptSummary || options.prompt || null;
    const normalizedPrompt = rawPrompt ? String(rawPrompt).replace(/\s+/g, ' ').trim() : null;
    const shortPrompt = normalizedPrompt ? (normalizedPrompt.length > 120 ? (normalizedPrompt.slice(0, 117) + '...') : normalizedPrompt) : null;
    let content = `🎯 任务: ${taskInfo}`;
    if (shortPrompt) {
        content += `

🧩 提示词摘要: ${shortPrompt}`;
    }
    content += `

${statusIcon} 状态: ${options.status === 'error' ? '失败' : options.status === 'warning' ? '警告' : '成功'}

⏰ 完成时间: ${timestamp}`;

    // 添加开始时间和时长
    if (startTimeStr) {
        content += `
🚀 开始时间: ${startTimeStr}
⏱️ 执行时长: ${formatDuration(duration)}`;
    }

    // 添加Token消耗
    if (options.tokens) {
        const { input, output, total, cacheRead, cacheWrite } = options.tokens;
        let tokenInfo = '';

        if (total !== undefined) {
            tokenInfo = `总计: ${total.toLocaleString()}`;
        } else if (input !== undefined && output !== undefined) {
            tokenInfo = `输入: ${input.toLocaleString()} | 输出: ${output.toLocaleString()} | 总计: ${(input + output).toLocaleString()}`;
        } else if (input !== undefined) {
            tokenInfo = `输入: ${input.toLocaleString()}`;
        }

        if (cacheRead !== undefined || cacheWrite !== undefined) {
            tokenInfo += ` (缓存读: ${cacheRead || 0} | 缓存写: ${cacheWrite || 0})`;
        }

        if (tokenInfo) {
            content += `
📊 Token消耗: ${tokenInfo}`;
        }
    }

    // 添加任务描述
    if (options.description) {
        content += `

📝 任务详情:
${options.description}`;
    }

    // 添加Git信息
    if (gitInfo) {
        content += `

🔧 仓库信息:
• 分支: ${gitInfo.branch}
• 提交: ${gitInfo.commitHash} - ${gitInfo.commitMessage}
• 作者: ${gitInfo.commitAuthor}
• 日期: ${gitInfo.commitTime}`;

        if (gitInfo.status) {
            content += `
• 工作区: ${gitInfo.status}`;
        }

        if (gitInfo.unpushed) {
            content += `
• ${gitInfo.unpushed}`;
        }
    }

    // 添加系统信息
    content += `

💻 环境: ${os.type()} ${os.release()}`;

    // 添加查看提示
    content += `

💡 可以查看执行结果了！`;

    try {
        // 发送富文本消息
        const success = await notifier.sendRichText(title, content);

        if (success) {
            console.log('🎉 任务完成通知已发送到飞书！');
            console.log('📱 您的手机将收到通知，小米手环会震动提醒');
        } else {
            console.log('❌ 飞书通知发送失败，请检查webhook配置');
        }

        return success;
    } catch (error) {
        console.error('❌ 发送飞书通知时发生错误:', error.message);
        return false;
    }
}

/**
 * 获取命令行参数
 */
function getCommandLineArgs() {
    const args = process.argv.slice(2);
    const options = {};

    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        if (arg.startsWith('--')) {
            const key = arg.slice(2);
            const value = args[i + 1] && !args[i + 1].startsWith('--') ? args[i + 1] : true;
            options[key] = value;
            if (value !== true) i++; // 跳过下一个参数，因为它已经被当作值处理了
        }
    }

    return options;
}

// 如果直接运行此脚本
if (require.main === module) {
    const cliArgs = getCommandLineArgs();
    const taskInfo = cliArgs.message || cliArgs.task || "Claude Code 任务已完成";
    const webhookUrl = cliArgs.webhook || null;
    const projectName = cliArgs.project || cliArgs.p || "";

    // 构建选项对象
    const options = {
        status: cliArgs.status || cliArgs.s || "success",
        description: cliArgs.description || cliArgs.desc || cliArgs.d || "",
        promptSummary: cliArgs.promptSummary || cliArgs.prompt || ""
    };

    // 处理开始时间
    if (cliArgs.startTime || cliArgs.start) {
        const startTimeStr = cliArgs.startTime || cliArgs.start;
        // 尝试解析为时间戳或ISO字符串
        const parsed = new Date(startTimeStr);
        if (!isNaN(parsed.getTime())) {
            options.startTime = parsed;
        } else {
            const timestamp = parseInt(startTimeStr);
            if (!isNaN(timestamp)) {
                options.startTime = timestamp;
            }
        }
    }

    // 处理Token消耗（格式：input,output 或 total）
    if (cliArgs.tokens) {
        const parts = cliArgs.tokens.split(',');
        if (parts.length === 1) {
            options.tokens = { total: parseInt(parts[0]) };
        } else if (parts.length >= 2) {
            options.tokens = {
                input: parseInt(parts[0]),
                output: parseInt(parts[1])
            };
        }
    }

    console.log('🚀 开始发送飞书通知...');
    notifyTaskCompletion(taskInfo, webhookUrl, projectName, options);
}

module.exports = {
    FeishuNotifier,
    notifyTaskCompletion
};
