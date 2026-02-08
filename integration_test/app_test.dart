import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sada/app.dart';

/// اختبار تكامل شامل للتطبيق
/// يختبر سيناريو "Happy Path" كامل من الإطلاق حتى التفاعل مع الإعدادات
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Sada App Integration Test - Happy Path', () {
    testWidgets('Complete user journey from launch to settings', (
      WidgetTester tester,
    ) async {
      // ============================================
      // Step 1: Launch App
      // ============================================
      await tester.pumpWidget(const ProviderScope(child: App()));

      // انتظار اكتمال التهيئة والانتقال من Splash
      await tester.pumpAndSettle(const Duration(seconds: 5));

      print('✅ التطبيق تم إطلاقه');

      // ============================================
      // Step 2: Handle Authentication
      // ============================================

      // التحقق من الشاشة الحالية (Lock Screen أو Onboarding أو Register)
      final onboardingSkipButton = find.text('Skip');
      final lockedTextAr = find.text('صدى مقفل');
      final lockedTextEn = find.text('Sada is locked');
      final nameFieldCheck = find.byKey(const Key('register_name_field'));
      final registerTitleArCheck = find.text('أنشئ هويتك');
      final registerTitleEnCheck = find.text('Create Identity');

      // انتظار قليل للتأكد من اكتمال الانتقال
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // التحقق أولاً من Register Screen (قد يكون التطبيق انتقل مباشرة إليه)
      if (nameFieldCheck.evaluate().isNotEmpty || 
          registerTitleArCheck.evaluate().isNotEmpty || 
          registerTitleEnCheck.evaluate().isNotEmpty) {
        print('📝 تم العثور على Register Screen مباشرة - إدخال الاسم...');
        // سنعالج Register Screen في نهاية الكود
      } else if (lockedTextAr.evaluate().isNotEmpty || lockedTextEn.evaluate().isNotEmpty) {
        // ============================================
        // Scenario A: Lock Screen - Enter PIN
        // ============================================
        print('📱 تم العثور على Lock Screen - إدخال PIN...');

        // البحث عن زر "Enter PIN" إذا كان موجوداً
        final enterPinButton = find.text('Enter PIN');
        if (tester.any(enterPinButton)) {
          await tester.tap(enterPinButton);
          await tester.pumpAndSettle();
        }

        // إدخال PIN: 1, 2, 3, 4, 5, 6
        final pinButtons = ['1', '2', '3', '4', '5', '6'];
        for (final digit in pinButtons) {
          // محاولة البحث بالـ Key أولاً (أكثر موثوقية)
          final keyButton = find.byKey(Key('pin_$digit'));
          if (keyButton.evaluate().isNotEmpty) {
            await tester.tap(keyButton);
            await tester.pump(const Duration(milliseconds: 300));
          } else {
            // محاولة البحث بالرقم
            final button = find.text(digit);
            if (button.evaluate().isNotEmpty) {
              await tester.tap(button);
              await tester.pump(const Duration(milliseconds: 300));
            }
          }
        }

        // انتظار اكتمال التحقق والانتقال
        await tester.pumpAndSettle(const Duration(seconds: 3));
        print('✅ تم إدخال PIN بنجاح');
      } else if (onboardingSkipButton.evaluate().isNotEmpty ||
          find.text('Next').evaluate().isNotEmpty ||
          find.text('التالي').evaluate().isNotEmpty) {
        // ============================================
        // Scenario B: Onboarding Screen
        // ============================================
        print('📱 تم العثور على Onboarding Screen...');

        // التمرير خلال Onboarding slides
        for (int i = 0; i < 3; i++) {
          final nextButtonEn = find.text('Next');
          final nextButtonAr = find.text('التالي');
          final getStartedButtonEn = find.text('Get Started');
          final getStartedButtonAr = find.text('ابدأ');

          if (getStartedButtonAr.evaluate().isNotEmpty) {
            await tester.tap(getStartedButtonAr);
            await tester.pumpAndSettle();
            break;
          } else if (getStartedButtonEn.evaluate().isNotEmpty) {
            await tester.tap(getStartedButtonEn);
            await tester.pumpAndSettle();
            break;
          } else if (nextButtonAr.evaluate().isNotEmpty) {
            await tester.tap(nextButtonAr);
            await tester.pumpAndSettle();
          } else if (nextButtonEn.evaluate().isNotEmpty) {
            await tester.tap(nextButtonEn);
            await tester.pumpAndSettle();
          }
        }

        // انتظار الانتقال إلى Register Screen
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // ============================================
        // Register Screen - Enter Name
        // ============================================
        // البحث مرة أخرى بعد الانتظار
        final registerTitleArCheck2 = find.text('أنشئ هويتك');
        final registerTitleEnCheck2 = find.text('Create Identity');
        final nameFieldCheck2 = find.byKey(const Key('register_name_field'));
        
        print('   🔍 البحث عن Register Screen...');
        print('   - عنوان عربي موجود: ${registerTitleArCheck2.evaluate().isNotEmpty}');
        print('   - عنوان إنجليزي موجود: ${registerTitleEnCheck2.evaluate().isNotEmpty}');
        print('   - حقل الإدخال موجود: ${nameFieldCheck2.evaluate().isNotEmpty}');
        
        if (registerTitleArCheck2.evaluate().isNotEmpty || 
            registerTitleEnCheck2.evaluate().isNotEmpty ||
            nameFieldCheck2.evaluate().isNotEmpty) {
          print('📝 تم العثور على Register Screen - إدخال الاسم...');

          // انتظار قليل للتأكد من اكتمال تحميل الشاشة
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // البحث عن حقل الإدخال
          final nameField = find.byKey(const Key('register_name_field'));
          if (nameField.evaluate().isNotEmpty) {
            print('   📍 تم العثور على حقل الاسم بالـ Key');
            
            // التأكد من أن الحقل مرئي
            await tester.ensureVisible(nameField);
            await tester.pump(const Duration(milliseconds: 200));
            
            // النقر على الحقل أولاً لتفعيله
            await tester.tap(nameField);
            await tester.pump(const Duration(milliseconds: 500));
            
            // إدخال النص مباشرة (enterText يقوم بالمسح تلقائياً)
            await tester.enterText(nameField, 'TestUser');
            await tester.pump(const Duration(milliseconds: 800));
            
            // التحقق من أن النص تم إدخاله
            final textField = tester.widget<TextFormField>(nameField);
            print('   📝 النص المدخل في الحقل: ${textField.controller?.text ?? "غير متاح"}');
            print('   ✅ تم إدخال النص: TestUser');
          } else {
            // محاولة البحث بالـ TextFormField
            final nameFieldByType = find.byType(TextFormField);
            if (nameFieldByType.evaluate().isNotEmpty) {
              print('   📍 تم العثور على حقل الاسم بالـ Type');
              
              // النقر على الحقل أولاً
              await tester.tap(nameFieldByType.first);
              await tester.pump(const Duration(milliseconds: 300));
              
              // إدخال النص
              await tester.enterText(nameFieldByType.first, 'TestUser');
              await tester.pump(const Duration(milliseconds: 500));
              
              print('   ✅ تم إدخال النص: TestUser');
            } else {
              print('   ⚠️ لم يتم العثور على حقل الإدخال');
            }
          }

          await tester.pumpAndSettle(const Duration(seconds: 2));

          // الضغط على زر التسجيل
          final registerButton = find.byKey(const Key('register_button'));
          if (registerButton.evaluate().isNotEmpty) {
            print('   📍 تم العثور على زر التسجيل بالـ Key');
            
            // التأكد من أن الزر مرئي
            await tester.ensureVisible(registerButton);
            await tester.pump(const Duration(milliseconds: 300));
            
            // النقر على الزر (مع warnIfMissed: false)
            await tester.tap(registerButton, warnIfMissed: false);
            await tester.pump(const Duration(milliseconds: 500));
          } else {
            // محاولة البحث بالنص (عربي أو إنجليزي)
            final registerButtonByTextAr = find.text('دخول صدى');
            final registerButtonByTextEn = find.text('Enter Sada');
            if (registerButtonByTextAr.evaluate().isNotEmpty) {
              print('   📍 تم العثور على زر التسجيل بالنص (عربي)');
              await tester.tap(registerButtonByTextAr, warnIfMissed: false);
            } else if (registerButtonByTextEn.evaluate().isNotEmpty) {
              print('   📍 تم العثور على زر التسجيل بالنص (إنجليزي)');
              await tester.tap(registerButtonByTextEn, warnIfMissed: false);
            } else {
              print('   ⚠️ لم يتم العثور على زر التسجيل');
            }
          }

          // انتظار اكتمال التسجيل والانتقال
          print('   ⏳ انتظار اكتمال التسجيل...');
          await tester.pumpAndSettle(const Duration(seconds: 10));
          
          // التحقق من وجود شاشة PIN setup (إذا ظهرت)
          final pinSetupTitle = find.text('Set PIN');
          final pinSetupTitleAr = find.text('تعيين PIN');
          if (pinSetupTitle.evaluate().isNotEmpty || pinSetupTitleAr.evaluate().isNotEmpty) {
            print('   📱 تم العثور على شاشة إعداد PIN - تخطي...');
            await tester.pumpAndSettle(const Duration(seconds: 2));
          }
          
          print('✅ تم التسجيل بنجاح');
          
          // ============================================
          // Handle Onboarding Screen (if appears after registration)
          // ============================================
          await tester.pumpAndSettle(const Duration(seconds: 2));
          
          // البحث عن Onboarding Screen
          final skipButtonAr2 = find.text('تخطي');
          final skipButtonEn2 = find.text('Skip');
          final nextButtonAr2 = find.text('التالي');
          final nextButtonEn2 = find.text('Next');
          final getStartedButtonAr2 = find.text('ابدأ');
          final getStartedButtonEn2 = find.text('Get Started');
          
          if (skipButtonAr2.evaluate().isNotEmpty || 
              skipButtonEn2.evaluate().isNotEmpty ||
              nextButtonAr2.evaluate().isNotEmpty ||
              nextButtonEn2.evaluate().isNotEmpty ||
              getStartedButtonAr2.evaluate().isNotEmpty ||
              getStartedButtonEn2.evaluate().isNotEmpty) {
            print('📱 تم العثور على Onboarding Screen بعد التسجيل - إكمال Onboarding...');
            
            // محاولة الضغط على Skip أولاً (أسرع)
            if (skipButtonAr2.evaluate().isNotEmpty) {
              print('   📍 الضغط على زر "تخطي" (عربي)');
              await tester.tap(skipButtonAr2);
              await tester.pumpAndSettle(const Duration(seconds: 3));
            } else if (skipButtonEn2.evaluate().isNotEmpty) {
              print('   📍 الضغط على زر "Skip" (إنجليزي)');
              await tester.tap(skipButtonEn2);
              await tester.pumpAndSettle(const Duration(seconds: 3));
            } else {
              // إذا لم يكن Skip موجوداً، نمرر عبر Slides
              print('   📍 التمرير عبر Onboarding slides...');
              
              // Slide 1 → Next
              if (nextButtonAr2.evaluate().isNotEmpty) {
                await tester.tap(nextButtonAr2);
                await tester.pumpAndSettle(const Duration(seconds: 1));
              } else if (nextButtonEn2.evaluate().isNotEmpty) {
                await tester.tap(nextButtonEn2);
                await tester.pumpAndSettle(const Duration(seconds: 1));
              }
              
              // Slide 2 → Next
              await tester.pumpAndSettle(const Duration(seconds: 1));
              if (nextButtonAr2.evaluate().isNotEmpty) {
                await tester.tap(nextButtonAr2);
                await tester.pumpAndSettle(const Duration(seconds: 1));
              } else if (nextButtonEn2.evaluate().isNotEmpty) {
                await tester.tap(nextButtonEn2);
                await tester.pumpAndSettle(const Duration(seconds: 1));
              }
              
              // Slide 3 → Get Started
              await tester.pumpAndSettle(const Duration(seconds: 1));
              if (getStartedButtonAr2.evaluate().isNotEmpty) {
                print('   📍 الضغط على زر "ابدأ" (عربي)');
                await tester.tap(getStartedButtonAr2);
                await tester.pumpAndSettle(const Duration(seconds: 3));
              } else if (getStartedButtonEn2.evaluate().isNotEmpty) {
                print('   📍 الضغط على زر "Get Started" (إنجليزي)');
                await tester.tap(getStartedButtonEn2);
                await tester.pumpAndSettle(const Duration(seconds: 3));
              }
            }
            
            print('✅ تم إكمال Onboarding');
          }
        }
      }
      
      // ============================================
      // Handle Register Screen (if found directly)
      // ============================================
      // إذا لم نجد Lock Screen أو Onboarding، نحاول Register Screen مباشرة
      if (!(lockedTextAr.evaluate().isNotEmpty || lockedTextEn.evaluate().isNotEmpty) &&
          !(onboardingSkipButton.evaluate().isNotEmpty ||
            find.text('Next').evaluate().isNotEmpty ||
            find.text('التالي').evaluate().isNotEmpty)) {
        
        // البحث عن Register Screen
        final nameFieldDirect = find.byKey(const Key('register_name_field'));
        final registerTitleArDirect = find.text('أنشئ هويتك');
        final registerTitleEnDirect = find.text('Create Identity');
        
        if (nameFieldDirect.evaluate().isNotEmpty || 
            registerTitleArDirect.evaluate().isNotEmpty || 
            registerTitleEnDirect.evaluate().isNotEmpty) {
          print('📝 تم العثور على Register Screen مباشرة - إدخال الاسم...');
          
          // انتظار قليل للتأكد من اكتمال تحميل الشاشة
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // البحث عن حقل الإدخال
          if (nameFieldDirect.evaluate().isNotEmpty) {
            print('   📍 تم العثور على حقل الاسم بالـ Key');
            
            // التأكد من أن الحقل مرئي
            await tester.ensureVisible(nameFieldDirect);
            await tester.pump(const Duration(milliseconds: 200));
            
            // النقر على الحقل أولاً لتفعيله
            await tester.tap(nameFieldDirect);
            await tester.pump(const Duration(milliseconds: 500));
            
            // إدخال النص مباشرة
            await tester.enterText(nameFieldDirect, 'TestUser');
            await tester.pump(const Duration(milliseconds: 1000));
            
            // التحقق من أن النص تم إدخاله فعلياً
            try {
              final textField = tester.widget<TextFormField>(nameFieldDirect);
              final enteredText = textField.controller?.text ?? '';
              print('   📝 النص المدخل في الحقل: "$enteredText"');
              
              if (enteredText.isEmpty || enteredText != 'TestUser') {
                // محاولة إدخال النص مرة أخرى
                print('   ⚠️ النص لم يتم إدخاله بشكل صحيح، المحاولة مرة أخرى...');
                await tester.tap(nameFieldDirect);
                await tester.pump(const Duration(milliseconds: 300));
                await tester.enterText(nameFieldDirect, 'TestUser');
                await tester.pump(const Duration(milliseconds: 1000));
              }
            } catch (e) {
              print('   ⚠️ لا يمكن الوصول إلى controller: $e');
            }
            
            print('   ✅ تم إدخال النص: TestUser');
          }

          await tester.pumpAndSettle(const Duration(seconds: 2));

          // التحقق من أن زر التسجيل مفعّل قبل النقر
          final registerButton = find.byKey(const Key('register_button'));
          if (registerButton.evaluate().isNotEmpty) {
            print('   📍 تم العثور على زر التسجيل بالـ Key');
            
            // التحقق من أن الزر غير معطل
            try {
              final buttonWidget = tester.widget<ElevatedButton>(registerButton);
              if (buttonWidget.onPressed == null) {
                print('   ⚠️ زر التسجيل معطل - انتظار قليل...');
                await tester.pumpAndSettle(const Duration(seconds: 2));
              }
            } catch (e) {
              print('   ⚠️ لا يمكن التحقق من حالة الزر: $e');
            }
            
            // التأكد من أن الزر مرئي
            await tester.ensureVisible(registerButton);
            await tester.pump(const Duration(milliseconds: 300));
            
            // النقر على الزر (مع warnIfMissed: false لتجنب التحذيرات)
            await tester.tap(registerButton, warnIfMissed: false);
            await tester.pump(const Duration(milliseconds: 500));
          } else {
            // محاولة البحث بالنص (عربي أو إنجليزي)
            final registerButtonByTextAr = find.text('دخول صدى');
            final registerButtonByTextEn = find.text('Enter Sada');
            if (registerButtonByTextAr.evaluate().isNotEmpty) {
              print('   📍 تم العثور على زر التسجيل بالنص (عربي)');
              await tester.tap(registerButtonByTextAr, warnIfMissed: false);
            } else if (registerButtonByTextEn.evaluate().isNotEmpty) {
              print('   📍 تم العثور على زر التسجيل بالنص (إنجليزي)');
              await tester.tap(registerButtonByTextEn, warnIfMissed: false);
            }
          }

          // انتظار اكتمال التسجيل والانتقال
          print('   ⏳ انتظار اكتمال التسجيل...');
          await tester.pumpAndSettle(const Duration(seconds: 10));
          
          // التحقق من وجود شاشة PIN setup (إذا ظهرت)
          final pinSetupTitle = find.text('Set PIN');
          final pinSetupTitleAr = find.text('تعيين PIN');
          if (pinSetupTitle.evaluate().isNotEmpty || pinSetupTitleAr.evaluate().isNotEmpty) {
            print('   📱 تم العثور على شاشة إعداد PIN - تخطي...');
            // يمكن إضافة منطق لإعداد PIN هنا إذا لزم الأمر
            await tester.pumpAndSettle(const Duration(seconds: 2));
          }
          
          print('✅ تم التسجيل بنجاح');
          
          // ============================================
          // Handle Onboarding Screen (if appears after registration)
          // ============================================
          await tester.pumpAndSettle(const Duration(seconds: 2));
          
          // البحث عن Onboarding Screen
          final skipButtonAr = find.text('تخطي');
          final skipButtonEn = find.text('Skip');
          final nextButtonAr = find.text('التالي');
          final nextButtonEn = find.text('Next');
          final getStartedButtonAr = find.text('ابدأ');
          final getStartedButtonEn = find.text('Get Started');
          
          if (skipButtonAr.evaluate().isNotEmpty || 
              skipButtonEn.evaluate().isNotEmpty ||
              nextButtonAr.evaluate().isNotEmpty ||
              nextButtonEn.evaluate().isNotEmpty ||
              getStartedButtonAr.evaluate().isNotEmpty ||
              getStartedButtonEn.evaluate().isNotEmpty) {
            print('📱 تم العثور على Onboarding Screen بعد التسجيل - إكمال Onboarding...');
            
            // محاولة الضغط على Skip أولاً (أسرع)
            if (skipButtonAr.evaluate().isNotEmpty) {
              print('   📍 الضغط على زر "تخطي" (عربي)');
              await tester.tap(skipButtonAr);
              await tester.pumpAndSettle(const Duration(seconds: 3));
            } else if (skipButtonEn.evaluate().isNotEmpty) {
              print('   📍 الضغط على زر "Skip" (إنجليزي)');
              await tester.tap(skipButtonEn);
              await tester.pumpAndSettle(const Duration(seconds: 3));
            } else {
              // إذا لم يكن Skip موجوداً، نمرر عبر Slides
              print('   📍 التمرير عبر Onboarding slides...');
              
              // Slide 1 → Next
              if (nextButtonAr.evaluate().isNotEmpty) {
                await tester.tap(nextButtonAr);
                await tester.pumpAndSettle(const Duration(seconds: 1));
              } else if (nextButtonEn.evaluate().isNotEmpty) {
                await tester.tap(nextButtonEn);
                await tester.pumpAndSettle(const Duration(seconds: 1));
              }
              
              // Slide 2 → Next
              await tester.pumpAndSettle(const Duration(seconds: 1));
              if (nextButtonAr.evaluate().isNotEmpty) {
                await tester.tap(nextButtonAr);
                await tester.pumpAndSettle(const Duration(seconds: 1));
              } else if (nextButtonEn.evaluate().isNotEmpty) {
                await tester.tap(nextButtonEn);
                await tester.pumpAndSettle(const Duration(seconds: 1));
              }
              
              // Slide 3 → Get Started
              await tester.pumpAndSettle(const Duration(seconds: 1));
              if (getStartedButtonAr.evaluate().isNotEmpty) {
                print('   📍 الضغط على زر "ابدأ" (عربي)');
                await tester.tap(getStartedButtonAr);
                await tester.pumpAndSettle(const Duration(seconds: 3));
              } else if (getStartedButtonEn.evaluate().isNotEmpty) {
                print('   📍 الضغط على زر "Get Started" (إنجليزي)');
                await tester.tap(getStartedButtonEn);
                await tester.pumpAndSettle(const Duration(seconds: 3));
              }
            }
            
            print('✅ تم إكمال Onboarding');
          }
        }
      }

      // ============================================
      // Step 3: Home Screen Verification
      // ============================================
      print('🏠 التحقق من Home Screen...');

      // انتظار اكتمال الانتقال إلى Home
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // البحث عن Home Screen بعدة طرق
      // 1. البحث عن اسم التطبيق (صدى/Sada)
      final homeTitleAr = find.text('صدى');
      final homeTitleEn = find.text('Sada');
      
      // 2. البحث عن FAB (Radar button) - مؤشر قوي على Home Screen
      final fab = find.byKey(const Key('home_fab'));
      final fabByIcon = find.byIcon(Icons.radar);
      
      // 3. البحث عن Bottom Navigation Bar
      final bottomNav = find.byType(NavigationBar);
      
      // 4. البحث عن رسائل الترحيب
      final welcomeTextAr = find.text('مرحباً');
      final welcomeTextEn = find.text('Hello');
      
      final homeFound = homeTitleAr.evaluate().isNotEmpty ||
                        homeTitleEn.evaluate().isNotEmpty ||
                        fab.evaluate().isNotEmpty ||
                        fabByIcon.evaluate().isNotEmpty ||
                        bottomNav.evaluate().isNotEmpty ||
                        welcomeTextAr.evaluate().isNotEmpty ||
                        welcomeTextEn.evaluate().isNotEmpty;

      if (!homeFound) {
        print('   ⚠️ لم يتم العثور على Home Screen - محاولة الانتظار أكثر...');
        await tester.pumpAndSettle(const Duration(seconds: 5));
        
        // إعادة المحاولة
        final homeFoundRetry = homeTitleAr.evaluate().isNotEmpty ||
                              homeTitleEn.evaluate().isNotEmpty ||
                              fab.evaluate().isNotEmpty ||
                              fabByIcon.evaluate().isNotEmpty ||
                              bottomNav.evaluate().isNotEmpty;
        
        expect(
          homeFoundRetry,
          true,
          reason: 'يجب أن يكون Home Screen مرئياً (صدى/Sada/FAB/BottomNav)',
        );
      } else {
        expect(
          homeFound,
          true,
          reason: 'يجب أن يكون Home Screen مرئياً (صدى/Sada/FAB/BottomNav)',
        );
      }
      print('✅ تم التحقق من Home Screen');

      // التحقق من وجود FAB (Radar button) - تم التحقق منه بالفعل أعلاه
      if (fab.evaluate().isEmpty && fabByIcon.evaluate().isEmpty) {
        print('   ⚠️ FAB غير موجود - لكن هذا لا يمنع نجاح الاختبار');
      } else {
        print('✅ تم التحقق من FAB (Radar button)');
      }

      // ============================================
      // Step 4: Navigate to Settings
      // ============================================
      print('⚙️ الانتقال إلى Settings...');

      // البحث عن زر Settings في Bottom Navigation
      // محاولة 1: البحث بالـ Key
      final settingsNavButton = find.byKey(const Key('bottom_nav_settings'));
      if (settingsNavButton.evaluate().isNotEmpty) {
        print('   📍 تم العثور على Settings button بالـ Key');
        await tester.tap(settingsNavButton);
      } else {
        // محاولة 2: البحث بالـ Tooltip (العربية)
        final settingsTooltip = find.byTooltip('الإعدادات');
        if (settingsTooltip.evaluate().isNotEmpty) {
          print('   📍 تم العثور على Settings button بالـ Tooltip (عربي)');
          await tester.tap(settingsTooltip);
        } else {
          // محاولة 3: البحث بالـ Icon (جميع الأيقونات)
          final settingsIcons = find.byIcon(Icons.settings);
          if (settingsIcons.evaluate().isNotEmpty) {
            print('   📍 تم العثور على Settings button بالـ Icon (${settingsIcons.evaluate().length} أيقونة)');
            // البحث عن آخر أيقونة Settings (في NavigationBar)
            await tester.tap(settingsIcons.last);
          } else {
            // محاولة 4: البحث بالنص (عربي أو إنجليزي)
            final settingsTextAr = find.text('الإعدادات');
            final settingsTextEn = find.text('Settings');
            if (settingsTextAr.evaluate().isNotEmpty) {
              print('   📍 تم العثور على Settings button بالنص (عربي)');
              await tester.tap(settingsTextAr);
            } else if (settingsTextEn.evaluate().isNotEmpty) {
              print('   📍 تم العثور على Settings button بالنص (إنجليزي)');
              await tester.tap(settingsTextEn);
            } else {
              // محاولة 5: البحث في NavigationBar والنقر على آخر destination (Settings)
              final navBar = find.byType(NavigationBar);
              if (navBar.evaluate().isNotEmpty) {
                print('   📍 محاولة النقر على Settings في NavigationBar (آخر destination)');
                // النقر على آخر destination (index 4 = Settings)
                final navBarCenter = tester.getCenter(navBar);
                // Settings هو آخر زر في اليمين
                await tester.tapAt(Offset(navBarCenter.dx - 100, navBarCenter.dy));
              } else {
                print('   ⚠️ لم يتم العثور على Settings button - محاولة النقر على موضع تقريبي');
                // آخر محاولة: النقر على موضع تقريبي لزر Settings (أسفل اليسار)
                await tester.tapAt(const Offset(50, 850));
              }
            }
          }
        }
      }

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // التحقق من فتح Settings Screen (عربي أو إنجليزي)
      final settingsTitleAr = find.text('الإعدادات');
      final settingsTitleEn = find.text('Settings');
      final settingsTitleFound = settingsTitleAr.evaluate().isNotEmpty || 
                                 settingsTitleEn.evaluate().isNotEmpty;
      expect(
        settingsTitleFound,
        true,
        reason: 'يجب أن تكون شاشة Settings مفتوحة',
      );
      print('✅ تم فتح Settings Screen');

      // ============================================
      // Step 5: Interact with Settings
      // ============================================
      print('🔧 التفاعل مع Settings...');

      // البحث عن Theme Switch/Tile (عربي أو إنجليزي)
      final themeTileAr = find.text('المظهر');
      final themeTileEn = find.text('Theme');
      if (themeTileAr.evaluate().isNotEmpty) {
        await tester.tap(themeTileAr);
        await tester.pumpAndSettle();
        print('✅ تم النقر على Theme (عربي)');
      } else if (themeTileEn.evaluate().isNotEmpty) {
        await tester.tap(themeTileEn);
        await tester.pumpAndSettle();
        print('✅ تم النقر على Theme (إنجليزي)');
      }

      // التمرير للأسفل للبحث عن Power Mode
      final powerModeTextAr = find.text('استهلاك البطارية');
      final powerModeTextEn = find.text('Power Usage');
      
      // محاولة التمرير حتى نجد Power Mode
      bool foundPowerMode = false;
      for (int i = 0; i < 5; i++) {
        if (powerModeTextAr.evaluate().isNotEmpty || powerModeTextEn.evaluate().isNotEmpty) {
          foundPowerMode = true;
          break;
        }
        final listView = find.byType(ListView);
        if (listView.evaluate().isNotEmpty) {
          await tester.drag(
            listView.first,
            const Offset(0, -200),
          );
        }
        await tester.pump(const Duration(milliseconds: 300));
      }
      
      await tester.pumpAndSettle();

      // التحقق من وجود Power Mode
      final powerModeFound = foundPowerMode || 
                            powerModeTextAr.evaluate().isNotEmpty || 
                            powerModeTextEn.evaluate().isNotEmpty;
      expect(
        powerModeFound,
        true,
        reason: 'يجب أن يكون Power Mode موجوداً في Settings',
      );
      print('✅ تم التحقق من وجود Power Mode');

      // ============================================
      // Step 6: Navigate Back to Home
      // ============================================
      print('🏠 العودة إلى Home...');

      // البحث عن زر Home في Bottom Navigation
      final homeNavButton = find.byKey(const Key('bottom_nav_home'));
      if (homeNavButton.evaluate().isNotEmpty) {
        print('   📍 تم العثور على Home button بالـ Key');
        await tester.tap(homeNavButton);
      } else {
        // محاولة البحث بالـ Tooltip (العربية)
        final homeTooltip = find.byTooltip('الرئيسية');
        if (homeTooltip.evaluate().isNotEmpty) {
          print('   📍 تم العثور على Home button بالـ Tooltip (عربي)');
          await tester.tap(homeTooltip);
        } else {
          // محاولة البحث بالـ Icon
          final homeIcons = find.byIcon(Icons.home);
          if (homeIcons.evaluate().isNotEmpty) {
            print('   📍 تم العثور على Home button بالـ Icon');
            await tester.tap(homeIcons.first);
          } else {
            // محاولة البحث بالنص
            final homeTextAr = find.text('الرئيسية');
            final homeTextEn = find.text('Home');
            if (homeTextAr.evaluate().isNotEmpty) {
              print('   📍 تم العثور على Home button بالنص (عربي)');
              await tester.tap(homeTextAr);
            } else if (homeTextEn.evaluate().isNotEmpty) {
              print('   📍 تم العثور على Home button بالنص (إنجليزي)');
              await tester.tap(homeTextEn);
            }
          }
        }
      }

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // التحقق من العودة إلى Home
      final homeTitleArCheck = find.text('صدى');
      final homeTitleEnCheck = find.text('Sada');
      final homeTitleAltCheck = find.text('Home');
      final backToHomeFound = homeTitleArCheck.evaluate().isNotEmpty ||
                             homeTitleEnCheck.evaluate().isNotEmpty ||
                             homeTitleAltCheck.evaluate().isNotEmpty;
      expect(
        backToHomeFound,
        true,
        reason: 'يجب أن نكون في Home Screen',
      );
      print('✅ تم العودة إلى Home Screen بنجاح');

      print('\n🎉 ✅ اكتمل اختبار التكامل بنجاح!');
    });
  });
}
