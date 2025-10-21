import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:atma_farm_app/services/weather_service.dart';
import 'package:atma_farm_app/models/weather_model.dart';
import 'package:atma_farm_app/services/tasks_service.dart';
import 'package:atma_farm_app/models/task_model.dart';
import 'package:atma_farm_app/models/farm_model.dart';

class HomeScreen extends StatefulWidget {
  final Farm farm;

  const HomeScreen({super.key, required this.farm});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userName;
  Weather? _weatherData;
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() { _isLoading = true; _errorMessage = null; });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { _errorMessage = "User not found."; _isLoading = false; });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        _userName = data['name'];
      }

      final farmData = widget.farm;
      
      // Correctly call the weather service with latitude and longitude
      _weatherData = await WeatherService().getWeather(farmData.location.latitude, farmData.location.longitude);

      if (farmData.plantationDate != null) {
        _tasks = TasksService().getTasksForPlantation(farmData.plantationDate!);
      } else {
        _tasks = [Task(title: "Plantation Date Not Set", description: "Update your profile to get tasks.")];
      }

    } catch (e) {
      _errorMessage = "Failed to load data: ${e.toString()}";
    } finally {
      if(mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Farm Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Scan for Problems'),
        icon: const Icon(Icons.camera_alt),
        backgroundColor: Colors.green.shade700,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'An error occurred: $_errorMessage',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchInitialData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _GreetingHeader(userName: _userName ?? 'Farmer'),
          const SizedBox(height: 24),
          _buildWeatherCard(),
          const SizedBox(height: 16),
          _buildTasksCard(),
          const SizedBox(height: 16),
          const _GyanGangaSection(),
          const SizedBox(height: 80), 
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    return _DashboardCard(
      title: 'Weather Forecast',
      icon: FontAwesomeIcons.cloudSun,
      iconColor: Colors.orangeAccent,
      child: _weatherData == null
          ? const Text('Could not load weather data.')
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_weatherData!.temperature.toStringAsFixed(1)}°C',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _weatherData!.condition,
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
                Image.network(
                  'https://openweathermap.org/img/wn/${_weatherData!.iconCode}@2x.png',
                  errorBuilder: (context, error, stackTrace) => const FaIcon(FontAwesomeIcons.cloud, color: Colors.grey),
                ),
              ],
            ),
    );
  }

  Widget _buildTasksCard() {
    return _DashboardCard(
      title: "Today's Tasks",
      icon: FontAwesomeIcons.solidSquareCheck,
      iconColor: Colors.blueAccent,
      child: _tasks.isEmpty
          ? const Text('No tasks for today. Enjoy your day!')
          : Column(
              children: _tasks.map((task) => _TaskItem(task: task)).toList(),
            ),
    );
  }
}

class _TaskItem extends StatefulWidget {
  final Task task;
  const _TaskItem({required this.task});

  @override
  State<_TaskItem> createState() => __TaskItemState();
}

class __TaskItemState extends State<_TaskItem> {
  late bool _isChecked;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.task.isDone;
  }

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(widget.task.title),
      subtitle: Text(widget.task.description),
      value: _isChecked,
      onChanged: (bool? value) {
        setState(() {
          _isChecked = value ?? false;
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(icon, color: iconColor, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1, color: Color(0xFFEEEEEE)),
            child,
          ],
        ),
      ),
    );
  }
}

class _GyanGangaSection extends StatelessWidget {
  const _GyanGangaSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gyan Ganga (Knowledge Stream)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return AspectRatio(
                aspectRatio: 9 / 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: NetworkImage('https://placehold.co/270x480/a9a9a9/ffffff?text=Video'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.play_circle_outline, size: 40, color: Colors.white70),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  final String userName;
  const _GreetingHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Namaste, $userName!',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.green.shade800,
      ),
    );
  }
}

