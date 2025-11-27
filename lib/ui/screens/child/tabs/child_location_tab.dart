import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quan_ly_cha_con/viewmodel/children/child_location_view_model.dart';

class ChildLocationTab extends StatelessWidget {
  const ChildLocationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChildLocationViewModel>();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          color: Colors.green[100],
          child: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text(
                'Đang chia sẻ vị trí tự động',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                if (viewModel.currentLocation != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vị trí hiện tại',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text('Lat: ${viewModel.currentLocation!.latitude.toStringAsFixed(6)}'),
                          Text('Lng: ${viewModel.currentLocation!.longitude.toStringAsFixed(6)}'),
                          Text('Độ chính xác: ${viewModel.currentLocation!.accuracy.toStringAsFixed(1)}m'),
                          const SizedBox(height: 12),
                          const Text(
                            "Vị trí đang được chia sẻ liên tục.\nKhông thể tắt ở chế độ con.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 20),
                Text(
                  'Tổng khoảng cách: ${viewModel.locationTrail.length} điểm',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
