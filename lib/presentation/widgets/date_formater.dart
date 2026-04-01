class DateFormater {  
  modifyDate(String date) {
    //string split by '/'
    List<String> removeHour = date.split(' ');
    List<String> sd = removeHour[0].split('-');
    String dateFormated = '${sd[2]}-${sd[1]}-${sd[0]}';
    return dateFormated;
  }
}