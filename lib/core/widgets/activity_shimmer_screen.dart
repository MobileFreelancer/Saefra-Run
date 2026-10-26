import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class ActivityShimmerScreen extends StatelessWidget {
  const ActivityShimmerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0D0D0D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// Title
              const Center(
                child: Text(
                  "Activity",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// Recent Runs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Recent Runs",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    "View All",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              ListView.builder(
                itemCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (_, index) {
                  return   Padding(
                    padding: EdgeInsets.only(bottom: 15),
                    child: ActivityCardShimmer(),
                  );
                },
              ),

              const SizedBox(height: 20),

              const Text(
                "Lifetime Performance",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 15),

              const BigPerformanceCard(),

              const SizedBox(height: 15),

              Row(
                children: const [

                  Expanded(child: SmallPerformanceCard()),

                  SizedBox(width: 15),

                  Expanded(child: SmallPerformanceCard()),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ActivityCardShimmer extends StatelessWidget {
  final  bool isActivity;
     const ActivityCardShimmer({super.key,this.isActivity=false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff171717),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [

          Row(
            children: [

              const CustomShimmer(
                width: 72,
                height: 72,
                radius: 10,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [

                    CustomShimmer(
                      width: 140,
                      height: 18,
                    ),

                    SizedBox(height: 10),

                    CustomShimmer(
                      width: 170,
                      height: 12,
                    ),

                    SizedBox(height: 8),

                    CustomShimmer(
                      width: 110,
                      height: 12,
                    ),
                  ],
                ),
              )
            ],
          ),

          const SizedBox(height: 16),

          isActivity? Row(
            children: const [

              Expanded(child: StatCard()),

              SizedBox(width: 10),

              Expanded(child: StatCard()),

              SizedBox(width: 10),

              Expanded(child: StatCard()),
            ],
          ):SizedBox.shrink()
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xff202020),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: const [

          CustomCircleShimmer(size: 18),

          SizedBox(height: 10),

          CustomShimmer(
            width: 50,
            height: 10,
          ),

          SizedBox(height: 8),

          CustomShimmer(
            width: 60,
            height: 12,
          ),
        ],
      ),
    );
  }
}

class BigPerformanceCard extends StatelessWidget {
  const BigPerformanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xff171717),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: const [

            CustomCircleShimmer(size: 52),

            SizedBox(width: 15),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                CustomShimmer(
                  width: 90,
                  height: 12,
                ),

                SizedBox(height: 12),

                CustomShimmer(
                  width: 170,
                  height: 30,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class SmallPerformanceCard extends StatelessWidget {
  const SmallPerformanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xff171717),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: CustomCircleShimmer(size: 40),
      ),
    );
  }
}

class CustomShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const CustomShimmer({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(seconds: 2),
      interval: const Duration(milliseconds: 200),
      color: Colors.white,
      colorOpacity: 0.25,
      enabled: true,
      direction: const ShimmerDirection.fromLTRB(),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class CustomCircleShimmer extends StatelessWidget {
  final double size;

  const CustomCircleShimmer({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(seconds: 2),
      interval: const Duration(milliseconds: 200),
      color: Colors.white,
      colorOpacity: 0.25,
      enabled: true,
      direction: const ShimmerDirection.fromLTRB(),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}