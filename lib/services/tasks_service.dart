import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:atma_farm_app/models/task_model.dart';

class TasksService {
  // This is a placeholder for a more complex GAP calendar.
  // In a real app, this logic would be more sophisticated, likely on a backend.
  List<Task> getTasksForPlantation(Timestamp plantationDate) {
    final now = DateTime.now();
    final plantedAt = plantationDate.toDate();
    
    // Calculate the age of the plantation in months
    final int monthsOld = (now.year - plantedAt.year) * 12 + now.month - plantedAt.month;

    if (monthsOld <= 6) {
      return [
        Task(title: "Weed Control", description: "Ensure the base of young palms is free from weeds."),
        Task(title: "Watering", description: "Water the saplings once every 2 days if there is no rain."),
        Task(title: "Check for Pests", description: "Look for signs of Rhinoceros beetle attack."),
      ];
    } else if (monthsOld <= 12) {
      return [
        Task(title: "Fertilizer Application", description: "Apply the recommended dose of NPK fertilizer."),
        Task(title: "Pruning", description: "Remove dry or dead leaves to keep the canopy clean."),
        Task(title: "Soil Moisture Check", description: "Ensure the soil is not too dry or waterlogged."),
      ];
    } else {
      return [
        Task(title: "Monitor for Ganoderma", description: "Check the base of the palms for signs of butt rot."),
        Task(title: "Harvest Readiness", description: "Check for loose fruits to estimate harvest time."),
        Task(title: "Canopy Management", description: "Continue to prune unproductive fronds."),
      ];
    }
  }
}
