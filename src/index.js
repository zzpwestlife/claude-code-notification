/**
 * Claude Code 任务完成通知系统
 * 仅支持飞书推送
 */

const os = require('os');
const fs = require('fs');
const path = require('path');
const { envConfig } = require('./shared/config/env');
const { NotificationManager } = require('./modules/notification/manager');

/**
 * 通知系统管理器
 */
class NotificationSystem {
    constructor() {
        this.config = this.loadConfig();
        this.projectName = this.getProjectName();
        this.notificationManager = new NotificationManager(this.config, this.projectName);
    }

    /**
     * 加载基准测试数据 (开始时间和Prompt)
     */
    loadBenchData() {
        try {
            const homeDir = os.homedir();
            const benchStartFile = path.join(homeDir, '.claude', 'bench', 'bench_start.json');
            
            if (fs.existsSync(benchStartFile)) {
                const data = JSON.parse(fs.readFileSync(benchStartFile, 'utf8'));
                // Python time.time() is in seconds, convert to ms
                const startTime = data.timestamp ? data.timestamp * 1000 : null;
                const prompt = data.prompt || null;
                
                console.log(`⏱️  检测到任务开始时间: ${new Date(startTime).toLocaleString()}`);
                if (prompt) console.log(`📝 检测到Prompt: ${prompt.substring(0, 50)}...`);
                
                return { startTime, prompt };
            }
        } catch (error) {
            // Ignore errors, bench data is optional
            console.log('⚠️  读取基准测试数据失败:', error.message);
        }
        return {};
    }

    /**
     * 加载配置文件
     */
    loadConfig() {
        try {
            const configPath = path.join(__dirname, '../config/config.json');
            const configData = fs.readFileSync(configPath, 'utf8');
            const config = JSON.parse(configData);

            // 从环境变量配置覆盖配置文件
            const envVars = envConfig.getAllConfig();

            // 飞书配置
            if (envVars.feishu.webhook_url) {
                config.notification.feishu.webhook_url = envVars.feishu.webhook_url;
                config.notification.feishu.enabled = true;
            }

            return config;
        } catch (error) {
            console.log('⚠️  无法加载配置文件，使用环境变量配置');
            const envVars = envConfig.getAllConfig();
            return {
                notification: {
                    feishu: envVars.feishu
                }
            };
        }
    }

    /**
     * 获取项目名称
     * 优先级: package.json > git仓库名 > 目录名
     */
    getProjectName() {
        try {
            // 1. 尝试从当前工作目录的 package.json 获取项目名称
            const packageJsonPath = path.join(process.cwd(), 'package.json');
            if (fs.existsSync(packageJsonPath)) {
                const packageData = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
                if (packageData.name) {
                    console.log(`📦 从 package.json 检测到项目名称: ${packageData.name}`);
                    return packageData.name;
                }
            }

            // 2. 尝试从 git 仓库名获取
            const { execSync } = require('child_process');
            try {
                const gitRemote = execSync('git remote get-url origin', {
                    encoding: 'utf8',
                    stdio: 'pipe'
                }).trim();
                // 从 git URL 提取仓库名
                const matches = gitRemote.match(/\/([^\/]+)\.git$/);
                if (matches && matches[1]) {
                    console.log(`🔧 从 git 仓库检测到项目名称: ${matches[1]}`);
                    return matches[1];
                }
            } catch (gitError) {
                // git 命令失败，继续下一步
            }

            // 3. 从当前目录名获取
            const dirName = path.basename(process.cwd());
            console.log(`📁 从目录名检测到项目名称: ${dirName}`);
            return dirName;

        } catch (error) {
            console.log('⚠️  无法获取项目名称，使用默认值');
            return '未知项目';
        }
    }

    /**
     * 发送所有类型的通知
     */
    async sendAllNotifications(taskInfo = "Claude Code 任务已完成", title = null) {
        const icons = this.notificationManager.getEnabledNotificationIcons();
        console.log(`🚀 开始发送任务完成通知... ${icons}`);
        console.log(`📁 项目名称：${this.projectName}`);
        console.log(`📝 任务信息：${taskInfo}`);

        // 加载基准测试数据
        const benchData = this.loadBenchData();
        const options = {
            startTime: benchData.startTime,
            prompt: benchData.prompt
        };

        // 发送所有通知
        const results = await this.notificationManager.sendAllNotifications(taskInfo, title, options);

        // 打印结果汇总
        this.notificationManager.printNotificationSummary(results);

        // 1秒后退出
        setTimeout(() => {
            console.log('✨ 通知系统执行完成，程序退出');
            process.exit(0);
        }, 1000);
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
            if (value !== true) i++;
        }
    }

    return options;
}

// 如果直接运行此脚本
if (require.main === module) {
    const options = getCommandLineArgs();
    const taskInfo = options.message || options.task || "Claude Code 任务已完成";
    const title = options.title || null;

    const notifier = new NotificationSystem();
    notifier.sendAllNotifications(taskInfo, title);
}

module.exports = {
    NotificationSystem
};
