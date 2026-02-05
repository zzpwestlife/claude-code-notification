/**
 * 环境变量配置管理模块
 * 统一处理所有环境变量的加载和配置
 */

const fs = require('fs');
const path = require('path');

/**
 * 环境变量配置类
 */
class EnvConfig {
    constructor() {
        this.loadEnvironmentVariables();
    }

    /**
     * 加载环境变量
     * 根据 NODE_ENV 加载对应的 config/.env.* 文件
     */
    loadEnvironmentVariables() {
        try {
            const nodeEnv = process.env.NODE_ENV || 'dev';
            const rootDir = path.resolve(__dirname, '../../../');
            
            // 定义可能的配置文件路径（按优先级排序）
            const envFiles = [
                path.join(rootDir, `config/.env.${nodeEnv}`), // config/.env.dev|prod|staging
                path.join(rootDir, 'config/.env'),            // config/.env
                path.join(rootDir, '.env')                    // .env (根目录，兼容旧版)
            ];

            let loaded = false;
            for (const envPath of envFiles) {
                if (fs.existsSync(envPath)) {
                    require('dotenv').config({ path: envPath });
                    console.log(`✅ 环境变量加载成功: ${path.relative(rootDir, envPath)}`);
                    loaded = true;
                    break;
                }
            }

            if (!loaded) {
                console.log('⚠️  未找到配置文件，使用系统环境变量');
                require('dotenv').config();
            }
        } catch (error) {
            console.log('❌ 环境变量加载失败:', error.message);
        }
    }

    /**
     * 获取飞书配置
     */
    getFeishuConfig() {
        return {
            webhook_url: process.env.FEISHU_WEBHOOK_URL || '',
            enabled: !!process.env.FEISHU_WEBHOOK_URL
        };
    }

    /**
     * 获取所有配置
     */
    getAllConfig() {
        return {
            feishu: this.getFeishuConfig()
        };
    }
}

// 导出单例实例
const envConfig = new EnvConfig();

module.exports = {
    EnvConfig,
    envConfig
};
