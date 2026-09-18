-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google_mlkit_text_recognition.** { *; }
-dontwarn com.google_mlkit_text_recognition.**

# iText7 rules for pdf_manipulator (required for release mode)
-keep public class com.itextpdf.** { *; }
-keep public class org.apache.** { *; }
-dontwarn com.itextpdf.**
-dontwarn org.apache.**
-dontwarn org.slf4j.**
