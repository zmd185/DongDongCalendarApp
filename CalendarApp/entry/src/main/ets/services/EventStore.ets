import relationalStore from '@ohos.data.relationalStore';
import { ValuesBucket } from '@kit.ArkData';
import CalendarEvent from '../model/Event';


@ObservedV2
export default class RdbUtils {

  private static rdbStore: relationalStore.RdbStore;
  @Trace events:Array<CalendarEvent>=[]
  @Trace SelectedDayEvents:Array<CalendarEvent>=[]
  static setStore(store: relationalStore.RdbStore) {
    RdbUtils.rdbStore = store;
  }
  static getStore(): relationalStore.RdbStore {
    return RdbUtils.rdbStore;
  }

  static executeSql(sql: string): Promise<void> {
    return RdbUtils.getStore().executeSql(sql);
  }
  static insert(tableName: string, data: ValuesBucket): Promise<number> {
    return RdbUtils.getStore().insert(tableName, data);
  }
  static queryAll(): Promise<Array<CalendarEvent>> {
    let predicates = new relationalStore.RdbPredicates('EVENTS');
    return new Promise<Array<CalendarEvent>>((resolve, reject) => {
      RdbUtils.getStore().query(predicates).then((result) => {
        let events = new Array<CalendarEvent>();
        while (result.goToNextRow()) {
          let event = new CalendarEvent(
            result.getLong(0),
            result.getString(1),
            result.getString(2),
            result.getLong(3),
            result.getLong(4),
            result.getLong(5),
            result.getLong(6),
            result.getLong(7),
            result.getLong(8),
            result.getLong(9),
            result.getLong(10) === 1,
            result.getLong(11) === 1,
            result.getLong(12)
          );
          events.push(event);
        }
        resolve(events);
      }).catch(() => {
        reject("查询出错了")
      })
    })
  }
  // 初始化数据库
  constructor() {

    const createTableSql = `
      CREATE TABLE IF NOT EXISTS EVENTS (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        location TEXT,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        date INTEGER NOT NULL,
        startHour INTEGER NOT NULL,
        startMinute INTEGER NOT NULL,
        endHour INTEGER NOT NULL,
        endMinute INTEGER NOT NULL,
        reminder INTEGER DEFAULT 0,
        allDay INTEGER DEFAULT 0,
        advanceMinutes INTEGER DEFAULT 0
      );
    `;
    RdbUtils.executeSql(createTableSql)
      .then(async ()=>{
        try {
          await RdbUtils.executeSql(`ALTER TABLE EVENTS ADD COLUMN reminder INTEGER DEFAULT 0;`);
        } catch (_) {}

        try {
          await RdbUtils.executeSql(`ALTER TABLE EVENTS ADD COLUMN allDay INTEGER DEFAULT 0;`);
        } catch (_) {}

        try {
          await RdbUtils.executeSql(`ALTER TABLE EVENTS ADD COLUMN advanceMinutes INTEGER DEFAULT 0;`);
        } catch (_) {}


        RdbUtils.queryAll()
          .then((events: Array<CalendarEvent>) => {
            this.events=events
            //this.reminderService.init()
          }).catch((error:Error) => {
          console.log(error.message)
        })
      })
  }

  public async getEventsOnSelectedDay(year: number, month: number, date: number): Promise<Array<CalendarEvent>> {
    try {
      const events: Array<CalendarEvent> = await RdbUtils.queryAll();
      this.events = events;

      return this.SelectedDayEvents=events.filter(event => {
        return event.year === year && event.month === month && event.date === date;
      });
    } catch (error) {
      return [];
    }
  }


  static deleteById(id: number) {
    let predicates = new relationalStore.RdbPredicates('EVENTS');
    predicates.equalTo('ID', id)
    return RdbUtils.getStore().delete(predicates);
  }

  static updateById(id: number, data: ValuesBucket) {
    let predicates = new relationalStore.RdbPredicates('EVENTS');
    predicates.equalTo('ID', id)
    return RdbUtils.getStore().update(data, predicates);
  }

  static async queryById(id: number): Promise<CalendarEvent | null> {
    let predicates = new relationalStore.RdbPredicates('EVENTS');
    predicates.equalTo('id', id); // 只查指定 id 的行

    try {
      const result = await RdbUtils.getStore().query(predicates);
      if (result.goToNextRow()) {
        return new CalendarEvent(
          result.getLong(0),   // id
          result.getString(1), // title
          result.getString(2), // location
          result.getLong(3),   // year
          result.getLong(4),   // month
          result.getLong(5),   // date
          result.getLong(6),   // startHour
          result.getLong(7),   // startMinute
          result.getLong(8),   // endHour
          result.getLong(9),   // endMinute
          result.getLong(10) === 1, // reminder
          result.getLong(11) === 1, // allDay
          result.getLong(12)        // advanceMinutes
        );
      } else {
        return null; // 没查到
      }
    } catch (error) {
      console.error(`查询 id=${id} 失败: ${JSON.stringify(error)}`);
      return null;
    }
  }
}

