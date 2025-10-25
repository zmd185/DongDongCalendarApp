import CalendarEvent from "../model/Event";
import RdbUtils from "../services/EventStore";
import { AppStorageV2 } from "@kit.ArkUI";
import { i18n } from '@kit.LocalizationKit';

interface lunar
{
  lunarYear: number,
  lunarMonth: number,
  lunarDay: number
}

@ObservedV2
export class GlobalDate {
  @Trace year: number = new Date().getFullYear();
  @Trace month: number = new Date().getMonth() + 1;
  @Trace selectedDate: Date = new Date(this.year,this.month-1,new Date().getDate());
  @Trace rowCount: number = 0;
  @Trace rows: Array<Array<number | undefined>> = [];
  @Trace currentWeek: (number | undefined)[] = [];
  @Trace CurrentWeekEvents:Array<Array<CalendarEvent>>=[]
  @Trace isShowDatePicker:boolean=false

  @Trace lunarRows: Array<Array<lunar | undefined>> = [];
  @Trace currentLunarWeek:(lunar|undefined)[]=[]
  CalendarRDB: RdbUtils = AppStorageV2.connect(RdbUtils, 'CALENDAR_RDB', () => new RdbUtils())!
  startIndex:number=0;
  endIndex:number=0;

  constructor() {
    this.updateMonth(this.year, this.month);
    this.updateCurrentWeekData()
    this.generateLunarRows()

  }

  private generateLunarRows(): void {
    let gregorian = i18n.getCalendar("zh-Hans", "gregory"); // 公历
    let lunar = i18n.getCalendar("zh-Hans", "chinese"); // 农历

    this.lunarRows = [];
    const currentDay = this.selectedDate.getDate();

    for (let r = 0; r < this.rows.length; r++) {
      let lunarRow: Array<lunar|undefined> = [];
      const row = this.rows[r];

      for (let c = 0; c < row.length; c++) {
        const day = row[c];
        if (day === undefined) {
          lunarRow.push(undefined);
          continue;
        }

        // 准确判定日期归属
        let tempYear = this.year;
        let tempMonth = this.month;

        // 计算该日期在整个网格中的绝对索引
        const absoluteIndex = r * 7 + c;

        // 如果超出本月范围，判断是否属于上月或下月
        if (absoluteIndex < this.startIndex) {
          // 上月
          tempMonth--;
          if (tempMonth < 1) {
            tempMonth = 12;
            tempYear--;
          }
        } else if (absoluteIndex > this.endIndex) {
          // 下月
          tempMonth++;
          if (tempMonth > 12) {
            tempMonth = 1;
            tempYear++;
          }
        }

        // 设置公历日期
        gregorian.setTime(new Date(tempYear, tempMonth - 1, day));
        // 转换到农历
        lunar.setTime(gregorian.getTimeInMillis());

        // 获取农历年月日
        const lunarYear = lunar.get("year");
        const lunarMonth = lunar.get("month"); // 注意：此处 0=正月
        const lunarDay = lunar.get("date");

        lunarRow.push({
          lunarYear,
          lunarMonth: lunarMonth + 1, // 转为 1~12 月
          lunarDay
        });
      }

      this.lunarRows.push(lunarRow);
    }
  }

  /** 获取指定月份的总天数 */
  private daysInMonth(year: number, month1to12: number): number {
    return new Date(year, month1to12, 0).getDate();
  }

  /** 获取指定月份的第一天是星期几 (0=周日, 6=周六) */
  private startWeekday(year: number, month1to12: number): number {
    return new Date(year, month1to12 - 1, 1).getDay();
  }

  /**
   * 根据 year/month 重新生成网格数据
   * 返回一个包含上个月末尾、本月所有日期、下个月开头的完整日历单元格数组。
   */
  private generateFullCells(): Array<number> {
    const cells: Array<number> = [];
    const year = this.year;
    const month = this.month; // 当前月份 (1-12)

    // ----------------------------------------------------
    // 计算上个月的日期（用于开头填充）
    // ----------------------------------------------------
    const firstWeekday = this.startWeekday(year, month); // 本月第一天是周几 (0-6)
    this.startIndex=firstWeekday;
    if (firstWeekday > 0) {
      const prevMonth = month === 1 ? 12 : month - 1;
      const prevYear = month === 1 ? year - 1 : year;
      const daysInPrevMonth = this.daysInMonth(prevYear, prevMonth);

      // 从上个月的倒数第 firstWeekday 天开始
      for (let i = firstWeekday; i > 0; i--) {
        cells.push(daysInPrevMonth - i + 1);
      }
    }

    const totalDays = this.daysInMonth(year, month);
    for (let d = 1; d <= totalDays; d++) {
      cells.push(d);
    }

    const totalCells = cells.length;
    let neededNextDays = 0;

    if (totalCells <= 35) {

      neededNextDays = 35 - totalCells;
    } else if (totalCells > 35 && totalCells <= 42) {
      neededNextDays = 42 - totalCells;
    }

    this.endIndex=cells.length-1
    for (let d = 1; d <= neededNextDays; d++) {
      cells.push(d);
    }

    return cells;
  }

  updateMonth(year: number, month: number): void {
    this.year = year;
    this.month = month;

    let fullCells = this.generateFullCells();

    this.rowCount = Math.ceil(fullCells.length / 7);
    this.rows = [];
    for (let r = 0; r < this.rowCount; r++) {
      this.rows.push(fullCells.slice(r * 7, r * 7 + 7));
    }
    this.generateLunarRows();
  }

  /**
   * 从 GlobalDate 的月视图网格中，提取包含 selectedDate 的那一周的数据
   */
  updateCurrentWeekData():void
  {
    const todayDay = this.selectedDate.getDate(); // 选中日期是几号
    const currentRows = this.rows;

    // 遍历所有行，找到包含选中日期（且位于本月范围内）的那一行
    for (let r = 0; r < currentRows.length; r++) {
      const row = currentRows[r];
      // 检查当前行中是否有 selectedDate.getDate() 对应的日期
      // 且确保它不是上个月或下个月的日期
      if (row.includes(todayDay))
      {
        // 找到日期在行中的索引（0-6）
        const dayIndexInRow = row.indexOf(todayDay);

        // 计算这个日期在 fullCells 数组中的绝对索引
        const absoluteIndex = r * 7 + dayIndexInRow;

        // 判断这个绝对索引是否在本月日期范围内
        if (absoluteIndex >= this.startIndex && absoluteIndex <= this.endIndex)
        {
          this.currentWeek=row;
        }
      }
    }
    this.updateCurrentLunarWeek()
  }

  private updateCurrentLunarWeek(): void {
    let gregorian = i18n.getCalendar("zh-Hans", "gregory");
    let lunar = i18n.getCalendar("zh-Hans", "chinese");

    this.currentLunarWeek = [];

    for (let i = 0; i < 7; i++) {
      const day = this.currentWeek[i];

      if (day === undefined) {
        this.currentLunarWeek.push(undefined);
        continue;
      }

      // ---- 日期归属判断 ----
      let tempYear = this.year;
      let tempMonth = this.month;

      const absoluteIndex = this.rows.indexOf(this.currentWeek) * 7 + i;

      if (absoluteIndex < this.startIndex) {
        tempMonth--;
        if (tempMonth < 1) {
          tempMonth = 12;
          tempYear--;
        }
      } else if (absoluteIndex > this.endIndex) {
        tempMonth++;
        if (tempMonth > 12) {
          tempMonth = 1;
          tempYear++;
        }
      }

      // ---- 设置公历日期并转农历 ----
      gregorian.setTime(new Date(tempYear, tempMonth - 1, day));
      lunar.setTime(gregorian.getTimeInMillis());

      const lunarYear = lunar.get("year");
      const lunarMonth = lunar.get("month");
      const lunarDay = lunar.get("date");

      this.currentLunarWeek.push({
        lunarYear,
        lunarMonth: lunarMonth + 1,
        lunarDay
      });
    }
  }


  getCurrentWeekEvents()
  {
    this.CurrentWeekEvents = []  // 清空旧数据

    for (let i = 0; i < 7; i++) {
      let eachDayEvents: Array<CalendarEvent> = []
      let day: number | undefined = this.currentWeek[i]
      if (day === undefined) {
        this.CurrentWeekEvents.push([])
        continue
      }

      // ---- 判断 day 所属月份 ----
      let tempYear = this.year
      let tempMonth = this.month

      const currentDay = this.selectedDate.getDate()

      // day 属于上个月
      if (day >= 20 && currentDay < 15) {
        tempMonth--
        if (tempMonth <= 0) {
          tempMonth = 12
          tempYear--
        }
      }
      // day 属于下个月
      else if (day <= 10 && currentDay > 20) {
        tempMonth++
        if (tempMonth >= 13) {
          tempMonth = 1
          tempYear++
        }
      }

      // ---- 查询数据库 ----
      this.CalendarRDB.getEventsOnSelectedDay(tempYear, tempMonth, day).then(events => {
        eachDayEvents = events
        // 注意：异步回调中更新数组要安全地操作
        this.CurrentWeekEvents[i] = eachDayEvents
      })

      // 提前放个空位，避免异步时数组长度不一致
      this.CurrentWeekEvents.push(eachDayEvents)
    }
  }

}