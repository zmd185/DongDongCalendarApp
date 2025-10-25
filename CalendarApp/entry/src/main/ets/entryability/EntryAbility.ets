import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import {  common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { calendarManager } from '@kit.CalendarKit';
import { notificationManager } from '@kit.NotificationKit';
import relationalStore from '@ohos.data.relationalStore'
import RdbUtils from '../services/EventStore';

const TAG: string = '[PublishOperation]';
const DOMAIN_NUMBER: number = 0xFF00;
const DOMAIN = 0x0000;
export let calendarMgr: calendarManager.CalendarManager | null = null;
export let mContext: common.UIAbilityContext | null = null;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
    relationalStore.deleteRdbStore(this.context, 'RdbTest.db', (err) => {
      if (err) {
        console.error(`Failed to delete RdbStore. Code:${err.code}, message:${err.message}`);
        return;
      }
      console.info('Succeeded in deleting RdbStore.');
    });
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 获取 UIAbilityContext（注意这里是 this.context）
    let context = this.context as common.UIAbilityContext;
    // 检查是否已经授权通知
    notificationManager.isNotificationEnabled().then((enabled: boolean) => {
      hilog.info(DOMAIN_NUMBER, TAG, `isNotificationEnabled: ${enabled}`);
      if (!enabled) {
        notificationManager.requestEnableNotification(context).then(() => {
          hilog.info(DOMAIN_NUMBER, TAG, `[ANS] requestEnableNotification success`);
        }).catch((err: BusinessError) => {
          if (1600004 == err.code) {
            hilog.error(DOMAIN_NUMBER, TAG, `[ANS] 用户拒绝授权，code=${err.code}, message=${err.message}`);
          } else {
            hilog.error(DOMAIN_NUMBER, TAG, `[ANS] 请求通知授权失败，code=${err.code}, message=${err.message}`);
          }
        });
      }
    }).catch((err: BusinessError) => {
      hilog.error(DOMAIN_NUMBER, TAG, `isNotificationEnabled fail, code=${err.code}, message=${err.message}`);
    });

    const STORE_CONFIG : relationalStore.StoreConfig= {
      name: 'Calendar.db', // 数据库文件名
      securityLevel: relationalStore.SecurityLevel.S1 // 数据库安全级别
    };

    relationalStore.getRdbStore(this.context, STORE_CONFIG, (err, store) => {
      if (err) {
        console.error(`Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
        return;
      }
      console.info(`Succeeded in getting RdbStore.`);
      RdbUtils.setStore(store)
    });

    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });

  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}