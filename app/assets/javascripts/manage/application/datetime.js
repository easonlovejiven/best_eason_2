$(function () {

  $('[data-provide="datepicker-inline"]').datetimepicker({
       format: 'YYYY-MM-DD',
       showClose: true,
       showClear: true,
    }
  );

  $('[data-provide="datepicker-time-inline"]').datetimepicker({
      format: 'YYYY-MM-DD HH:mm',
      useCurrent: false,
      showClose: true,
      showClear: true,
    }
  );

  $('[data-provide="datepicker-time-second-inline"]').datetimepicker({
      format: 'YYYY-MM-DD HH:mm:ss',
      useCurrent: false,
      showClose: true,
      showClear: true,
    }
  );
})
