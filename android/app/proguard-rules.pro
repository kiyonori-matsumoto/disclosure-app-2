# WorkManager & Room
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keepclassmembers class androidx.work.impl.WorkDatabase_Impl {
    public <init>();
}

-keep class * extends androidx.room.RoomDatabase {
    public <init>();
}
-keep class androidx.room.** { *; }

-dontwarn androidx.work.impl.**
