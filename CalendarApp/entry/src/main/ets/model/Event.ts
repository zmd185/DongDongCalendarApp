export default class CalendarEvent {
    id: number;
    title: string;
    location: string;
    year: number;
    month: number;
    date: number;
    startHour: number;
    startMinute: number;
    endHour: number;
    endMinute: number;
    reminder: boolean;
    allDay: boolean;
    advanceMinutes: number

    constructor(id: number, title:string,location:string,year:number,month:number, date: number,startHour: number,startMinute: number,endHour: number,endMinute: number,reminder:boolean,allDay: boolean,advanceMinutes: number) {
        this.id = id;
        this.title = title;
        this.location=location;
        this.year = year;
        this.month = month;
        this.date = date;
        this.startHour=startHour
        this.startMinute=startMinute
        this.endHour=endHour
        this.endMinute=endMinute
        this.reminder=reminder
        this.allDay=allDay
        this.advanceMinutes=advanceMinutes
    }
}


