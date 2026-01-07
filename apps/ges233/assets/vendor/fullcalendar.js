document.addEventListener("DOMContentLoaded", function () {
  const eventsScript = document.getElementById("calendar-events");
  var events = [];

  if (eventsScript) {
    try {
      events = JSON.parse(eventsScript.textContent);
    } catch (e) {
      console.error("解析日历事件失败", e);
    }
  }

    const calendarEl = document.getElementById("calendar");
    const calendar = new FullCalendar.Calendar(calendarEl, {
      initialView: "dayGridMonth",
      events: events,
      locale: "zh-cn",
    });

    calendar.render();
});
