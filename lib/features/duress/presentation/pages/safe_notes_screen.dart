import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/mesh_gradient_background.dart';

class SafeNote {
  final String title;
  final String content;
  final String category;

  const SafeNote({
    required this.title,
    required this.content,
    required this.category,
  });
}

class SafeNotesScreen extends StatelessWidget {
  const SafeNotesScreen({super.key});

  List<SafeNote> get _notes {
    // Innocent content suitable for showing during confiscation
    return const [
      SafeNote(
        category: 'Work',
        title: 'Meeting Notes - Aug 15',
        content: 'Agenda:\n1. Q3 Budget Review\n2. New Marketing Campaign ideas\n3. Team building event planning\n\nAction Items:\n- Send report by Friday\n- Call supplier for quotes',
      ),
      SafeNote(
        category: 'Personal',
        title: 'Grocery List',
        content: '- Milk\n- Eggs\n- Bread (Whole wheat)\n- Apples\n- Chicken breast\n- Rice\n- Tomatoes\n- Olive oil',
      ),
      SafeNote(
        category: 'Recipes',
        title: 'Grandma\'s Lentil Soup',
        content: 'Ingredients:\n- 1 cup red lentils\n- 1 onion, chopped\n- 2 carrots, diced\n- 1 tsp cumin\n- Salt & pepper\n\nMethod:\nFry onion and carrots. Add lentils and water. Simmer for 20 mins. Blend if desired. Serve with lemon.',
      ),
      SafeNote(
        category: 'Ideas',
        title: 'App Ideas',
        content: '1. Plant watering reminder\n2. Book club organizer\n3. Local coffee shop finder\n4. Daily habit tracker with simple UI',
      ),
      SafeNote(
        category: 'Poetry',
        title: 'Favorite Poem',
        content: 'The woods are lovely, dark and deep,\nBut I have promises to keep,\nAnd miles to go before I sleep,\nAnd miles to go before I sleep.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'My Notes',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: _notes.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final note = _notes[index];
            return GlassCard(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            note.category,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy, size: 18.sp, color: Colors.grey),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: note.content));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Copied to clipboard')),
                            );
                          },
                          tooltip: 'Copy Note',
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      note.title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      note.content,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
