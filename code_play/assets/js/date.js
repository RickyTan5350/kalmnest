// assets/js/date.js
var myDate = {
  now: function() {
    return new Date().toString();
  },
  getYear: function() {
    return new Date().getFullYear();
  }
};
Date.today = function() {
    return new Date().toString();
};