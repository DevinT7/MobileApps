// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart'; // Import webview_flutter package
import 'package:share_plus/share_plus.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_place/google_place.dart';
import 'package:timezone/timezone.dart' as tz; // Import the timezone package
import 'package:timezone/data/latest.dart' as tz;






class MyApp extends StatelessWidget {
  
  @override

  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synthaze',
      theme: Provider.of<ThemeNotifier>(context).getTheme(),
      home:  HabitTrackerHomePage(),
    );
  }
}
class UserPoints {
  int points = 0;
  DateTime lastResetDate = DateTime.now(); // Initialize with current date

  void addPoints(int amount) {
    _checkResetPoints();
    points += amount;
  }

  void subtractPoints(int amount) {
    _checkResetPoints();
    points -= amount;
  }

  void _checkResetPoints() {
    // Check if current date is different from last reset date (different day)
    if (DateTime.now().day != lastResetDate.day) {
      // Reset points and update last reset date
      points = 0;
      lastResetDate = DateTime.now();
    }
  }
}

class LocationService {
  geo.Geolocator _geolocator = geo.Geolocator();

  Future<bool> requestPermission() async {
    final permission = await geo.Geolocator.requestPermission();
    return permission == geo.LocationPermission.always ||
        permission == geo.LocationPermission.whileInUse;
  }

  Future<geo.Position> getCurrentLocation() async {
    bool serviceEnabled;
    geo.LocationPermission permission;

    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS service not enabled');
    }

    permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied, we cannot request permissions.');
    }

    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission != geo.LocationPermission.whileInUse &&
          permission != geo.LocationPermission.always) {
        throw Exception('Location permissions are denied (actual value: $permission).');
      }
    }

    return await geo.Geolocator.getCurrentPosition();
  }
}


void main() {
  runApp(
    ChangeNotifierProvider(
      
      create: (_) => ThemeNotifier(),
      child: MyApp(),
    ),
  );
}

class AdvicePage extends StatelessWidget {
  final EmbeddedLink link;

  const AdvicePage(this.link);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(link.title),
      ),
      body: WebView(
        initialUrl: link.url,
        javascriptMode: JavascriptMode.unrestricted, // Ensure JavaScript is unrestricted
      ),
    );
  }
}
class FavoriteQuotesPage extends StatefulWidget {
  final List<String> favoriteQuotes;

  FavoriteQuotesPage(this.favoriteQuotes);

  @override
  _FavoriteQuotesPageState createState() => _FavoriteQuotesPageState();
}

class _FavoriteQuotesPageState extends State<FavoriteQuotesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorite Quotes'),
      ),
      body: ListView.builder(
        itemCount: widget.favoriteQuotes.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    widget.favoriteQuotes[index],
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showClearConfirmationDialog(context);
        },
        label: Text('Clear Favorite Quotes'),
        icon: Icon(Icons.clear),
        backgroundColor: Color.fromARGB(255, 144, 153, 249),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showClearConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear Favorite Quotes?'),
          content: Text('Are you sure you want to clear all favorite quotes?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _clearFavoriteQuotes();
                Navigator.of(context).pop();
              },
              child: Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _clearFavoriteQuotes() {
    setState(() {
      widget.favoriteQuotes.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Favorite quotes cleared'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  ThemeData getTheme() {
    return _themeMode == ThemeMode.dark ? ThemeData.dark() : ThemeData.light();
  }
}
class CustomWeeklyCalendar extends StatefulWidget {
  final List<Habit> habits;
  final Function(DateTime) onDateSelected;

 CustomWeeklyCalendar(this.habits, {required this.onDateSelected});

  @override
  _CustomWeeklyCalendarState createState() => _CustomWeeklyCalendarState();
}

class _CustomWeeklyCalendarState extends State<CustomWeeklyCalendar> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  late CalendarFormat _calendarFormat;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _calendarFormat = CalendarFormat.week;
    tz.initializeTimeZones();
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      calendarFormat: _calendarFormat,
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
        });
        widget.onDateSelected(selectedDay); // Call the callback function
      },
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}










class Habit {
  String name;
  final int frequency;
  final List<DateTime> completedDates;
  DateTime? dueDate;
  TimeOfDay? dueTime; // Add dueTime property for selecting time
  int? recurrenceFrequency; // New property for recurrence frequency
  DateTime? recurrenceEndDate; // New property for recurrence end date

  Habit(this.name, this.frequency, this.completedDates, {this.dueDate, this.dueTime, this.recurrenceFrequency, this.recurrenceEndDate});

  void markCompleted(DateTime date) {
    completedDates.add(date);
    if (dueDate != null && !completedDates.contains(dueDate)) {
      completedDates.add(dueDate!);
    }
  }

  void markIncomplete(DateTime date) {
    completedDates.remove(date);
  }

  bool isCompleted(DateTime date) {
    return completedDates.contains(date);
  }

  int getCurrentStreak() {
    int streak = 0;
    DateTime today = DateTime.now();

    for (int i = completedDates.length - 1; i >= 0; i--) {
      if (today.difference(completedDates[i]).inDays <= 1) {
        streak++;
      } else {
        break;
      }
      today = completedDates[i];
    }

    return streak;
  }

  void updateName(String newName) {
    name = newName;
  }

  Widget buildHomePage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Synthaze'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Habit Name: $name',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              'Frequency: $frequency',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              'Completed Dates: ${completedDates.toString()}',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              'Current Streak: ${getCurrentStreak()}',
              style: TextStyle(fontSize: 20),
            ),
            if (dueTime != null)
              Text(
                'Due Time: ${dueTime!.format(context)}',
                style: TextStyle(fontSize: 20),
              ),
            if (recurrenceFrequency != null)
              Text(
                'Recurrence Frequency: $recurrenceFrequency times per week',
                style: TextStyle(fontSize: 20),
              ),
            if (recurrenceEndDate != null)
              Text(
                'Recurrence End Date: ${DateFormat('MM/dd/yyyy').format(recurrenceEndDate!)}',
                style: TextStyle(fontSize: 20),
              ),
          ],
        ),
      ),
    );
  }
}


class MoodEntry {
  final String mood;
  final String feelings;
  final DateTime date;
  bool isHovering;

  MoodEntry(this.mood, this.feelings, this.date, {this.isHovering = false});
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synthaze',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 144, 153, 249),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}


class HabitTrackerHomePage extends StatefulWidget {
  const HabitTrackerHomePage({Key? key}) : super(key: key);

  @override
  _HabitTrackerHomePageState createState() => _HabitTrackerHomePageState();
}

class _HabitTrackerHomePageState extends State<HabitTrackerHomePage> {
    DateTime _selectedDate = DateTime.now(); // Track selected date

  UserPoints userPoints = UserPoints();
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
       @override
void initState() {
  super.initState();
  _initializeNotifications();
  // Schedule notifications for existing habits
  for (var habit in habits) {
    if (habit.dueDate != null) {
      _scheduleNotification(habit.name, habit.dueDate!);
    }
  }
}


  

      
  // Function to navigate to the journal page with authentication check
  List<Habit> habits = [
    Habit('Exercise', 1, []),
    Habit('Read', 7, []),
  ];
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  void _clearMoodEntries() {
    setState(() {
      moodEntries.clear();
    });
  }
  Future<void> _initializeNotifications() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings();
    final MacOSInitializationSettings initializationSettingsMacOS =
        MacOSInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            macOS: initializationSettingsMacOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }
  void _scheduleNotification(String habitName, DateTime dueDate) async {
  final AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'habits_channel',
    'Habits Channel',
    'Channel for habit notifications',
    importance: Importance.max,
    priority: Priority.high,
  );
  final IOSNotificationDetails iOSPlatformChannelSpecifics =
      IOSNotificationDetails();
  final MacOSNotificationDetails macOSPlatformChannelSpecifics =
      MacOSNotificationDetails();
  final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
      macOS: macOSPlatformChannelSpecifics);

  // Schedule the notification at the specific time of the due date
  // await flutterLocalNotificationsPlugin.zonedSchedule(
  //   0, // Notification ID
  //   'Synthase', // Notification title
  //   'Don\'t forget to complete $habitName today!', // Notification body
  //   //tz.TZDateTime.from(dueDate.add(Duration(minutes: 0)), tz.local), // Add 1 minute to ensure notification time is in the future
  //   //platformChannelSpecifics,
  //   androidAllowWhileIdle: true,
  //   uiLocalNotificationDateInterpretation:
  //       UILocalNotificationDateInterpretation.absoluteTime,
  //   matchDateTimeComponents: DateTimeComponents.time,
  // );
}



// tz.TZDateTime _nextInstanceOfDueDate(DateTime dueDate) {
//   final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
//   tz.TZDateTime scheduledDate =
//       tz.TZDateTime(tz.local, dueDate.year, dueDate.month, dueDate.day);
//   if (scheduledDate.isBefore(now)) {
//     scheduledDate = scheduledDate.add(const Duration(days: 1));
//   }
//   return scheduledDate;
// }


  List<EmbeddedLink> adviceLinks = [
    EmbeddedLink(
        title: '5 Tips for Better Sleep', url: 'https://www.sleepfoundation.org/articles/sleep-hygiene'),
    EmbeddedLink(
        title: 'How to Stay Productive During the Day',
        url: 'https://www.forbes.com/sites/johnhall/2017/08/06/8-habits-of-productive-people/?sh=58c925e3706c'),
    EmbeddedLink(title: 'Your Third Link', url: 'https://www.example.com/link3'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Synthaze',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 144, 153, 249),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              // Navigate to user profile page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: <Widget>[
          _buildHomePage(),
          _buildAdvicePage(),
          _buildMoodPage(),
          _buildFillerPage(), // New filler page
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 144, 153, 249), // Updated color
        selectedItemColor: Color.fromARGB(255, 27, 60, 208),
        unselectedItemColor: const Color.fromARGB(255, 144, 153, 249),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_quote_rounded),
            label: 'Quotes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Journal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run_rounded), // Icon for the home page
            label: 'Activities', // Label for the home page
          ),
        ],
      ),
    );
  }


Widget _buildHomePage() {
  // Filter habits by due date matching the selected date
  List<Habit> upcomingHabits = habits.where((habit) {
    return habit.dueDate != null && isSameDay(habit.dueDate!, _selectedDate);
  }).toList();

  return Scaffold(
    appBar: AppBar(
      //title: Text('Synthaze'),
    ),
    body: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 0), // Add some space at the top
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
              ),
              child: Text(
                'Weekly Calendar', // Updated label
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CustomWeeklyCalendar(habits, onDateSelected: (DateTime date) {
              setState(() {
                _selectedDate = date; // Update selected date when user selects a date on the calendar
              });
            }), // Pass the habits list and a callback to handle date selection
          ),
          SizedBox(height: 16), // Add some space between calendar and upcoming habits
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
              ),
              child: Text(
                'Upcoming Tasks for ${DateFormat('MM/dd/yy').format(_selectedDate)}', // Updated label with selected date
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: upcomingHabits.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      upcomingHabits[index].name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Due: ${DateFormat('MM/dd/yy').format(upcomingHabits[index].dueDate!)}',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    trailing: Checkbox(
                      value: upcomingHabits[index].isCompleted(_selectedDate), // Use completion status of the habit
                      onChanged: (bool? value) {
                        setState(() {
                          // Toggle completion status of the habit
                          if (value != null) {
                            if (value) {
                              upcomingHabits[index].markCompleted(_selectedDate);
                              // Remove the habit from the list when completed
                              upcomingHabits.removeAt(index);
                            } else {
                              upcomingHabits[index].markIncomplete(_selectedDate);
                            }
                          }
                        });
                      },
                    ),
                    // Add more details or actions if needed
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
              ),
              child: Text(
                'Tasks', // Updated label
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          AnimatedList(
            key: _listKey,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            initialItemCount: habits.length,
            itemBuilder: (context, index, animation) {
              return _buildHabitItem(habits[index], animation);
            },
          ),
        ],
      ),
    ),
    floatingActionButton: Padding(
      padding: EdgeInsets.only(top: 30, right: 10), // Adjust top padding as needed
      child: Align(
        alignment: Alignment.topRight,
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              _addNewHabit(Habit('New Task', 1, []));
            });
          },
          child: Icon(Icons.add),
        ),
      ),
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
  );
}





void _addNewHabit(Habit habit) {
  final int index = habits.length;
  habits.add(habit);
  _listKey.currentState!.insertItem(index);
}









  Widget _buildHabitItem(Habit habit, Animation<double> animation) {
  TextEditingController habitNameController = TextEditingController(text: habit.name);
  return SizeTransition(
    sizeFactor: animation,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        child: ListTile(
          title: Text(
            habit.name,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          trailing: Checkbox(
            value: habit.isCompleted(DateTime.now()), // Check if habit is completed today
            onChanged: (_) {
              setState(() {
                _toggleHabitCompletion(habit);
              });
            },
          ),
          onTap: () {
            _showRenameHabitDialog(habit, habitNameController);
          },
        ),
      ),
    ),
  );
}



  void _removeHabitWithAnimation(Habit habit) {
    final index = habits.indexOf(habit);
    habits.removeAt(index);
    _listKey.currentState!.removeItem(
      index,
      (context, animation) => _buildHabitItem(habit, animation),
      duration: Duration(milliseconds: 500),
    );
    // Add points when habit is completed
    userPoints.addPoints(10); // For example, completing a habit could earn 10 points
  }
   void _toggleHabitCompletion(Habit habit) {
  setState(() {
    if (habit.isCompleted(DateTime.now())) {
      habit.markIncomplete(DateTime.now());
    } else {
      habit.markCompleted(DateTime.now());
    }
  });
}




  // Widget _buildPointsWidget() {
  //   return Container(
  //     padding: EdgeInsets.all(8),
  //     decoration: BoxDecoration(
  //       color: Colors.black.withOpacity(0.5),
  //       borderRadius: BorderRadius.circular(10),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Icon(
  //           Icons.star,
  //           color: Colors.yellow,
  //         ),
  //         SizedBox(width: 5),
  //         Text(
  //           'Points: ${userPoints.points}',
  //           style: TextStyle(
  //             color: Colors.white,
  //             fontSize: 16,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
void _addOrUpdateHabit(Habit habit) {
  setState(() {
    if (!habits.contains(habit)) {
      habits.add(habit);
      _scheduleNotification(habit.name, habit.dueDate!);
    } else {
      habits[habits.indexWhere((element) => element.name == habit.name)] = habit;
      _scheduleNotification(habit.name, habit.dueDate!);
    }
  });
}




void _showRenameHabitDialog(Habit habit, TextEditingController habitNameController) {
  DateTime? selectedDate = habit.dueDate;
  TimeOfDay? selectedTime;
  int? recurrenceFrequency;
  DateTime? recurrenceEndDate;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit Habit'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: habitNameController,
                    decoration: InputDecoration(hintText: 'Enter new habit name'),
                  ),
                  SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Due Date:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(DateTime.now().year + 1),
                          );
                          if (pickedDate != null && pickedDate != selectedDate) {
                            setState(() {
                              selectedDate = pickedDate;
                              selectedTime ??= TimeOfDay.now();
                            });
                          }
                        },
                        child: Text(
                          selectedDate != null ? 'Change Date' : 'Select Date',
                          style: TextStyle(color: Color.fromARGB(255, 144, 153, 249)),
                        ),
                      ),
                      if (selectedDate != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                            Text(
                              'Select Due Time:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () async {
                                final TimeOfDay? pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime ?? TimeOfDay.now(),
                                );
                                if (pickedTime != null && pickedTime != selectedTime) {
                                  setState(() {
                                    selectedTime = pickedTime;
                                  });
                                }
                              },
                              child: Text(
                                'Select Time',
                                style: TextStyle(color: Color.fromARGB(255, 144, 153, 249)),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recurring:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      CheckboxListTile(
  contentPadding: EdgeInsets.zero,
  title: Text(
    'Enable Recurring',
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
  ),
  controlAffinity: ListTileControlAffinity.trailing,
  value: recurrenceFrequency != null,
  onChanged: (bool? value) {
    setState(() {
      if (value != null && value) {
        // Enable recurring
        recurrenceFrequency = 1; // Default frequency
      } else {
        // Disable recurring
        recurrenceFrequency = null;
        recurrenceEndDate = null;
      }
    });
  },
  activeColor: Colors.blue, // Change color when checked
),

                      if (recurrenceFrequency != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                            Text(
                              'Frequency:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            DropdownButtonFormField<int>(
                              value: recurrenceFrequency,
                              items: [
                                DropdownMenuItem<int>(
                                  value: 1,
                                  child: Text('Hourly'),
                                ),
                                DropdownMenuItem<int>(
                                  value: 2,
                                  child: Text('Daily'),
                                ),
                                DropdownMenuItem<int>(
                                  value: 3,
                                  child: Text('Weekdays'),
                                ),
                                DropdownMenuItem<int>(
                                  value: 4,
                                  child: Text('Weekends'),
                                ),
                                DropdownMenuItem<int>(
                                  value: 5,
                                  child: Text('Weekly'),
                                ),
                                DropdownMenuItem<int>(
                                  value: 6,
                                  child: Text('Biweekly'),
                                ),
                                DropdownMenuItem<int>(
                                  value: 7,
                                  child: Text('Monthly'),
                                ),
                                DropdownMenuItem<int>(
                                  value: 8,
                                  child: Text('Every 3 Months'),
                                ),
                                DropdownMenuItem<int>(
                                  value: 9,
                                  child: Text('Every 6 Months'),
                                ),
                                DropdownMenuItem<int>(
                                  value: 10,
                                  child: Text('Yearly'),
                                ),
                              ],
                              onChanged: (int? value) {
                                setState(() {
                                  recurrenceFrequency = value;
                                });
                              },
                            ),
                            SizedBox(height: 10),
                            Text(
                              'End Recurrence On:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () async {
                                final DateTime? pickedEndDate = await showDatePicker(
                                  context: context,
                                  initialDate: recurrenceEndDate ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(DateTime.now().year + 1),
                                );
                                if (pickedEndDate != null && pickedEndDate != recurrenceEndDate) {
                                  setState(() {
                                    recurrenceEndDate = pickedEndDate;
                                  });
                                }
                              },
                              child: Text(
                                recurrenceEndDate != null ? 'Change End Date' : 'Select End Date',
                                style: TextStyle(color: Color.fromARGB(255, 144, 153, 249)),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    habit.updateName(habitNameController.text);
                    // Handle selected date and time here
                    if (selectedDate != null) {
                      selectedTime ??= TimeOfDay.now();
                      final dueDateTime = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day,
                          selectedTime!.hour, selectedTime!.minute);
                      // Update the dueDateTime of the habit
                      habit.dueDate = dueDateTime;
                    }
                    if (recurrenceFrequency != null) {
                      habit.recurrenceFrequency = recurrenceFrequency;
                      habit.recurrenceEndDate = recurrenceEndDate;
                    } else {
                      habit.recurrenceFrequency = null;
                      habit.recurrenceEndDate = null;
                    }
                    _addOrUpdateHabit(habit); // Add or update habit
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}







  Widget _buildAdvicePage() {
  return PageView(
    children: <Widget>[
      _buildQuoteCarousel(),
    ],
  );
}


Widget _buildQuoteCarousel() {
    final ThemeData theme = Theme.of(context);

    List<String> favoritedQuotes = []; // Track favorited quotes

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            itemCount: adviceQuotes.length,
            itemBuilder: (context, index) {
              final bool isFavorited = favoritedQuotes.contains(adviceQuotes[index]);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      width: 350,
                      height: 200,
                      decoration: BoxDecoration(
                        color: theme.cardColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            adviceQuotes[index],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge!.color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: isFavorited ? Colors.red : null,
                        ),
                        onPressed: () {
                          setState(() {
                            if (isFavorited) {
                              favoritedQuotes.remove(adviceQuotes[index]);
                              favoriteQuotes.remove(adviceQuotes[index]);
                            } else {
                              favoritedQuotes.add(adviceQuotes[index]);
                              favoriteQuotes.add(adviceQuotes[index]);
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.share),
                        onPressed: () {
                          print("Sharing quote...");
                          Share.share("${adviceQuotes[index]}\n\nShared from Synthaze");
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FavoriteQuotesPage(favoriteQuotes)),
            );
          },
          child: Text("Favorite quotes"),
        ),
      ],
    );
  }









Widget _buildQuoteItem(String quote) {
  return Container(
    width: 250,
    margin: EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          spreadRadius: 2,
          blurRadius: 5,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          quote,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

// Define a list of quotes
List<String> adviceQuotes = [
  "The only way to do great work is to love what you do. \n\n– Steve Jobs",
  "Believe you can and you're halfway there. \n\n–Theodore Roosevelt",
  "The only limit to our realization of tomorrow will be our doubts of today. \n\n–Franklin D. Roosevelt",
  "Creativity is intelligence having fun. \n\n–Albert Einstein",
  "Don't let yesterday take up too much of today. \n\n–Will Rogers",
  "The purpose of life is not to be happy. It is to be useful, to be honorable, to be compassionate, to have it make some difference that you have lived and lived well. \n\n– Ralph Waldo Emerson",
  "You have to be burning with an idea, or a problem, or a wrong that you want to right. If you’re not burning with something, it’s not enough. \n\n– Judy Woodruff",
  "Our greatest glory is not in never falling, but in rising every time we fall. \n\n – Nelson Mandela",
  "Difficulties in life are intended to make us stronger, not to break us.\n\n – Roy T. Bennett"
  
];

List<String> favoriteQuotes = [];



  
Widget _buildMoodPage() {
  return Stack(
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Welcome to Your Journal!',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8),
                Text(
                  'Start documenting your thoughts and feelings to reflect on later. Tap the button below to begin your journal entry.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildMoodEntriesList(),
          ),
        ],
      ),
      Positioned(
        bottom: 16.0,
        left: 16.0,
        child: FloatingActionButton.extended(
          heroTag: 'clearButton', // Unique hero tag for the clear button
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Clear Journal Entries'),
                  content: const Text('Are you sure you want to clear all recorded Journals?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        _clearMoodEntries();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Confirm'),
                    ),
                  ],
                );
              },
            );
          },
          label: Text('Clear'),
          icon: Icon(Icons.clear),
          backgroundColor: const Color.fromARGB(255, 144, 153, 249),
        ),
      ),
      Positioned(
        bottom: 16.0,
        right: 16.0,
        child: FloatingActionButton.extended(
          heroTag: 'startButton', // Unique hero tag for the start button
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MoodEntryPage(onSave: _saveMoodEntry)),
            );
          },
          label: Text('Start Journal Entry'),
          icon: Icon(Icons.edit),
          backgroundColor: const Color.fromARGB(255, 144, 153, 249),
        ),
      ),
    ],
  );
}



  

  Future<bool> _authenticate() async {
    bool isAuthenticated = false;
    try {
      isAuthenticated = await _localAuthentication.authenticate(
        localizedReason: 'Authenticate to access the journal page', // Displayed on Face ID prompt
      );
    } catch (e) {
      print('Error authenticating: $e');
    }
    return isAuthenticated;
  }






  Widget _buildMoodEntriesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: moodEntries.length,
      itemBuilder: (context, index) {
        final moodEntry = moodEntries[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MoodDetailsPage(moodEntry)),
            );
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) {
              setState(() {
                moodEntry.isHovering = true;
              });
            },
            onExit: (_) {
              setState(() {
                moodEntry.isHovering = false;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
                color: moodEntry.isHovering ? Colors.grey[200] : Colors.transparent,
              ),
              child: ListTile(
                title: Text(moodEntry.mood),
                subtitle: Text('Date: ${DateFormat('MM/dd/yyyy').format(moodEntry.date)}'),
              ),
            ),
          ),
        );
      },
    );
  }

  void _saveMoodEntry(String mood, String feelings) {
    final newMoodEntry = MoodEntry(mood, feelings, DateTime.now());
    setState(() {
      moodEntries.add(newMoodEntry);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  // New filler page widget
  Widget _buildFillerPage() {
    return HomePage();
  }
}



class DarkModeToggle extends StatefulWidget {
  @override
  _DarkModeToggleState createState() => _DarkModeToggleState();
}

class _DarkModeToggleState extends State<DarkModeToggle> {
  @override
  Widget build(BuildContext context) {
    ThemeMode themeMode = Provider.of<ThemeNotifier>(context).themeMode;

    return SwitchListTile(
      title: Text('Dark Mode'),
      value: themeMode == ThemeMode.dark,
      onChanged: (value) {
        ThemeNotifier themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
        themeNotifier.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
      },
    );
  }
}








class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'John Doe';
    });
  }

  Future<void> _updateUserName(String newName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = newName;
    });
    await prefs.setString('userName', newName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.person,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            UserNameDisplay(userName: _userName),
            SizedBox(height: 20),
            DarkModeToggle(),
            SizedBox(height: 20),
            MatchSystemThemeButton(),
            SizedBox(height: 20),
            ProfileSettings(onNameUpdate: _updateUserName),
          ],
        ),
      ),
    );
  }
}

class UserNameDisplay extends StatelessWidget {
  final String userName;

  const UserNameDisplay({
    Key? key,
    required this.userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      userName,
      style: TextStyle(fontSize: 20),
    );
  }
}

class ProfileSettings extends StatelessWidget {
  final Function(String) onNameUpdate;

  const ProfileSettings({
    Key? key,
    required this.onNameUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Implement logic to change display name
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  TextEditingController controller = TextEditingController();
                  return AlertDialog(
                    title: Text('Change Display Name'),
                    content: TextField(
                      controller: controller,
                      decoration: InputDecoration(labelText: 'New Display Name'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Add logic to save new display name
                          String newName = controller.text;
                          onNameUpdate(newName);
                          Navigator.of(context).pop();
                        },
                        child: Text('Save'),
                      ),
                    ],
                  );
                },
              );
            },
            child: Text('Change Display Name'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Implement logic to change email
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Change Email'),
                    content: TextField(
                      decoration: InputDecoration(labelText: 'New Email'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Add logic to save new email
                          Navigator.of(context).pop();
                        },
                        child: Text('Save'),
                      ),
                    ],
                  );
                },
              );
            },
            child: Text('Change Email'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Implement logic to change profile picture
              // This might involve using image picker libraries
            },
            child: Text('Change Profile Picture'),
          ),
        ),
      ],
    );
  }
}



class MatchSystemThemeButton extends StatefulWidget {
  @override
  _MatchSystemThemeButtonState createState() => _MatchSystemThemeButtonState();
}

class _MatchSystemThemeButtonState extends State<MatchSystemThemeButton> {
  Brightness _systemBrightness = WidgetsBinding.instance!.window.platformBrightness;

  @override
  void initState() {
    super.initState();
    // Listen for changes in system brightness
    WidgetsBinding.instance!.window.onPlatformBrightnessChanged = () {
      setState(() {
        _systemBrightness = WidgetsBinding.instance!.window.platformBrightness;
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    ThemeNotifier themeNotifier = Provider.of<ThemeNotifier>(context);
    ThemeMode themeMode =
        _systemBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;

    return SwitchListTile(
      title: Text('Match System Theme'),
      value: themeNotifier.themeMode == themeMode,
      onChanged: (value) {
        themeNotifier.setThemeMode(themeMode);
      },
    );
  }
}







class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 30.0),
            const Text(
              'Welcome to Synthaze...',
              style: TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30.0),
            TextFormField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                String username = 'user';
                String password = 'password';

                if (usernameController.text == username &&
                    passwordController.text == password) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HabitTrackerHomePage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Invalid username or password'),
                    duration: Duration(seconds: 2),
                  ));
                }
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: const Center(
        child: Text('Settings Page'),
      ),
    );
  }
}


class MoodEntryPage extends StatefulWidget {
  final Function(String mood, String feelings) onSave;

  const MoodEntryPage({Key? key, required this.onSave}) : super(key: key);

  @override
  _MoodEntryPageState createState() => _MoodEntryPageState();
}

class _MoodEntryPageState extends State<MoodEntryPage> {
  final TextEditingController moodController = TextEditingController();
  final TextEditingController feelingsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Mood'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'How are you feeling today?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: moodController,
              decoration: const InputDecoration(
                hintText: 'Enter your mood',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Additional Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: feelingsController,
              decoration: const InputDecoration(
                hintText: 'Enter your feelings',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                widget.onSave(moodController.text, feelingsController.text);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class MoodDetailsPage extends StatefulWidget {
  final MoodEntry moodEntry;

  const MoodDetailsPage(this.moodEntry, {Key? key}) : super(key: key);

  @override
  _MoodDetailsPageState createState() => _MoodDetailsPageState();
}

class _MoodDetailsPageState extends State<MoodDetailsPage> {
  late TextEditingController _moodController;
  late TextEditingController _feelingsController;
  bool _isEditable = false;

  @override
  void initState() {
    super.initState();
    _moodController = TextEditingController(text: widget.moodEntry.mood);
    _feelingsController = TextEditingController(text: widget.moodEntry.feelings);
  }

  @override
  void dispose() {
    _moodController.dispose();
    _feelingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Details'),
        actions: [
          IconButton(
            icon: Icon(_isEditable ? Icons.save : Icons.edit),
            onPressed: _toggleEditability,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Opacity(
              opacity: _isEditable ? 1.0 : 1.0, // Adjust opacity as needed
              child: TextFormField(
                controller: _moodController,
                decoration: InputDecoration(labelText: 'Mood'),
                enabled: _isEditable,
              ),
            ),
            SizedBox(height: 10),
            Opacity(
              opacity: _isEditable ? 1.0 : 1.0, // Adjust opacity as needed
              child: TextFormField(
                controller: _feelingsController,
                decoration: InputDecoration(labelText: 'Feelings'),
                enabled: _isEditable,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Date: ${DateFormat('MM/dd/yyyy').format(widget.moodEntry.date)}',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
      floatingActionButton: _isEditable
          ? FloatingActionButton.extended(
              onPressed: _toggleEditability,
              label: Text('Done Editing'),
              icon: Icon(Icons.done),
              backgroundColor: Color.fromARGB(255, 144, 153, 249), // Customize the button color here
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _toggleEditability() {
    setState(() {
      _isEditable = !_isEditable;
    });
  }
}

class EmbeddedLink {
  final String title;
  final String url;

  EmbeddedLink({required this.title, required this.url});
}

List<MoodEntry> moodEntries = [];

// New page class representing the home page




class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraPosition _initialCameraPosition;
  late String _dailyQuote;
  late double _dailyProgress;
  late TextEditingController _messageController = TextEditingController();
  List<String> _chatMessages = [];
  List<String> _nearbyActivities = [];
  LatLng? _pickedLocation;
  final LocationService _locationService = LocationService();



  @override
  void initState() {
    super.initState();
    _fetchDailyQuote();
    _calculateDailyProgress();
    _fetchNearbyActivities();
    _requestLocationPermission(); // Request location permission on init
  }

  Future<void> _requestLocationPermission() async {
    bool permissionGranted = await _locationService.requestPermission();
    if (permissionGranted) {
      _fetchCurrentLocation();
    } else {

      // Handle case when permission is not granted
      // You can show a dialog to inform the user about the necessity of location access
    }
  }

  // Method to fetch the current location
  Future<void> _fetchCurrentLocation() async {
    try {
      geo.Position position = await _locationService.getCurrentLocation();
      _updateNearbyActivitiesMap(position);
      setState(() {
        _initialCameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14.0,
        );
      });
    } catch (e) {
      print("Error fetching current location: $e");
    }
  }

  void _fetchDailyQuote() {
    // Dummy list of quotes
    List<String> quotes = [
      "The only way to do great work is to love what you do. – Steve Jobs",
      "Believe you can and you're halfway there. –Theodore Roosevelt",
      "The only limit to our realization of tomorrow will be our doubts of today. –Franklin D. Roosevelt",
      "Creativity is intelligence having fun. –Albert Einstein",
      "Don't let yesterday take up too much of today. –Will Rogers",
    ];

    // Randomly select a quote
    int index = Random().nextInt(quotes.length);
    setState(() {
      _dailyQuote = quotes[index];
    });
  }

  void _calculateDailyProgress() {
    // Dummy progress value
    double progress = Random().nextDouble() * 100;

    setState(() {
      _dailyProgress = progress;
    });
  }

  void _openChatScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(messageController: _messageController),
      ),
    );
  }

  Future<void> _fetchNearbyActivities() async {
    try {
      // Get the current position of the device
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Display Google Maps with nearby activities markers
      _updateNearbyActivitiesMap(position);

      // Update initial camera position to the user's current location
      setState(() {
        _initialCameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14.0,
        );
      });
    } catch (e) {
      print("Error fetching nearby activities: $e");
    }
  }

  void _updateNearbyActivitiesMap(Position position) {
    // Dummy list of nearby activities
    _nearbyActivities = [
      'Park',
      'Library',
      'Museum',
      'Restaurant',
      'Gym',
    ];

    setState(() {
      // Update nearby activities
      _nearbyActivities = _nearbyActivities;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dummy list of activities
    List<String> activities = [
      'Go for a walk in the park',
      'Read a book',
      'Learn a new language',
      'Cook a new recipe',
      'Do some yoga',
      'Write in a journal',
      'Practice meditation',
      'Watch a documentary',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        actions: [
          IconButton(
            icon: Icon(Icons.chat),
            onPressed: _openChatScreen,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Nearby Activities:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(activities[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              flex: 2,
              child: Container(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: _initialCameraPosition,
                      markers: _buildMarkers(),
                      onLongPress: _handleMapLongPress,
                    ),
                    if (_pickedLocation != null)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: ElevatedButton(
                          onPressed: () {
                            _getDirections(_pickedLocation!);
                          },
                          child: Text('Get Directions'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    return _nearbyActivities.map((activity) {
      return Marker(
        markerId: MarkerId(activity),
        position: LatLng(
          _initialCameraPosition.target.latitude,
          _initialCameraPosition.target.longitude,
        ),
        infoWindow: InfoWindow(
          title: activity,
          snippet: 'Tap to view details',
        ),
        onTap: () {
          // Handle marker tap event
        },
      );
    }).toSet();
  }

  void _handleMapLongPress(LatLng latLng) {
    setState(() {
      _pickedLocation = latLng;
    });
  }

  void _getDirections(LatLng destination) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch maps application.'),
        ),
      );
    }
  }
}



class ChatScreen extends StatefulWidget {
  final TextEditingController messageController;

  const ChatScreen({Key? key, required this.messageController}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}



class _ChatScreenState extends State<ChatScreen> {
  late List<String> _chatMessages = [];
  final TextEditingController _messageController = TextEditingController();

  

  // Function to send message to OpenAI API
void _sendMessage(String message) async {
  const String apiKey = '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'; // Replace with your actual API key
  const String apiUrl = 'https://api.openai.com/v1/chat/completions';

  // Add the user's message to the chat
  setState(() {
    _chatMessages.add("You: $message");
  });

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo-1106',
        'messages': [
          {'role': 'system', 'content': 'You: $message'},
          {'role': 'user', 'content': 'Bot: Error processing message'}
        ],
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final botResponse = data['choices'][0]['message']['content'];
      setState(() {
        // Add the bot's response to the chat
        _chatMessages.add("Synthase: $botResponse");
      });
    } else {
      print('Request failed with status: ${response.statusCode}');
      print('Response body: ${response.body}');
      setState(() {
        _chatMessages.add("Synthase: Error processing message");
      });
    }
  } catch (e) { 
    print('Error: $e');
    setState(() {
      _chatMessages.add("Synthase: Error processing message");
    });
  }

  _messageController.clear();
}










  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with Synthaze'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: _chatMessages[index].startsWith('Synthase') ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _chatMessages[index].startsWith('Synthase') ? Colors.blueAccent : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _chatMessages[index],
                        style: TextStyle(color: _chatMessages[index].startsWith('Synthase') ? Colors.white : Colors.black),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      _sendMessage(_messageController.text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}