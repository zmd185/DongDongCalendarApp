import notificationManager from '@ohos.notificationManager'
import Prompt from '@system.prompt'
import wantAgent from '@ohos.app.ability.wantAgent';
import CalendarEvent from '../model/Event';
import RdbUtils from './EventStore';
import { AppStorageV2 } from '@kit.ArkUI';

class reminderService {
  CalendarRDB: RdbUtils = AppStorageV2.connect(RdbUtils, 'CALENDAR_RDB', () => new RdbUtils())!
  private timers: Map<number, number> = new Map()
  public  isInit:boolean=false
  /**
   * 初始化：扫描所有事件，计算延迟时间并安排通知
   */
  async init() {
    this.CalendarRDB.events = await RdbUtils.queryAll();
    if (!this.CalendarRDB?.events?.length) {
      return
    }

    const now = new Date()

    for (let event of this.CalendarRDB.events) {
      if (!event.reminder) continue // 未开启提醒的跳过

      if (this.timers.has(event.id)) continue

      if(event.allDay)
      {
        this.delayedPublishNotification(0, event)
      }

      // 计算事件开始时间
      const eventTime = new Date(event.year, event.month - 1, event.date, event.startHour, event.startMinute)

      // 提前提醒的时间点
      const reminderTime = new Date(eventTime.getTime() - event.advanceMinutes * 60 * 1000)

      const delayMs = reminderTime.getTime() - now.getTime()

      if (delayMs > 0)
      {
        this.delayedPublishNotification(delayMs, event)
      }
      else if (now < eventTime)
      {
        // 提醒时间已过，但活动还没开始 → 立即提醒
        this.delayedPublishNotification(0, event)
      }
    }
  }

  async updateReminder(eventId:number)
  {
    const event = await RdbUtils.queryById(eventId);
    if(event===null)return

    if(event.allDay)
    {
      this.delayedPublishNotification(0, event)
    }
    const now = new Date()
    // 计算事件开始时间
    const eventTime = new Date(event.year, event.month - 1, event.date, event.startHour, event.startMinute)

    // 提前提醒的时间点
    const reminderTime = new Date(eventTime.getTime() - event.advanceMinutes * 60 * 1000)

    const delayMs = reminderTime.getTime() - now.getTime()
    if (delayMs > 0)
    {
      this.delayedPublishNotification(delayMs, event)
    }
    else if (now < eventTime)
    {
      // 提醒时间已过，但活动还没开始 → 立即提醒
      this.delayedPublishNotification(0, event)
    }
  }

  deleteReminder(eventId:number)
  {
    if (this.timers.has(eventId))
    {
      clearTimeout(this.timers.get(eventId))
      this.timers.delete(eventId)
    }
  }

  /**
   * 延迟发布通知
   */
  async delayedPublishNotification(delayMs: number, event: CalendarEvent) {
    Prompt.showToast({ message: `将在 ${Math.floor(delayMs / 1000)} 秒后提醒 ${event.title}`, duration: 2000 })

    const timerId =setTimeout(() => {
      this.publishNotification(event)
    }, delayMs)

    this.timers.set(event.id, timerId)
  }

  /**
   * 发布单个事件的通知
   */
  async publishNotification(event: CalendarEvent) {
    try {

      // Step 1: 创建 WantAgent（点击通知时打开应用）
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [{
          deviceId: '',
          bundleName: 'com.example.calendarapp',
          abilityName: 'EntryAbility'
        }],
        operationType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      }

      const wantAgentObj = await wantAgent.getWantAgent(wantAgentInfo)

      // Step 2: 构建通知
      const notificationRequest: notificationManager.NotificationRequest = {
        id: event.id,
        notificationSlotType: notificationManager.SlotType.SERVICE_INFORMATION,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: `提醒：${event.title}`,
            text: `${event.location || '无地点信息'} ${event.startHour}:${event.startMinute.toString().padStart(2, '0')}`,
            additionalText: '点击打开查看详情'
          }
        },
        wantAgent: wantAgentObj
      }

      // Step 3: 发布通知
      await notificationManager.publish(notificationRequest)
      Prompt.showToast({ message: `已发布提醒：${event.title}`, duration: 2000 })
    }
    catch (err) {
      console.error(`发布失败: ${JSON.stringify(err)}`)
    }
  }
}

export default reminderService
