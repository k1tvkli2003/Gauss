# Keep JLaTeXMath / Markwon reflective bits used by the LaTeX renderer.
-keep class io.noties.markwon.** { *; }
-keep class ru.noties.jlatexmath.** { *; }
-keep class org.scilab.forge.jlatexmath.** { *; }
-dontwarn org.scilab.forge.jlatexmath.**

# Room generated implementations.
-keep class * extends androidx.room.RoomDatabase { *; }
-dontwarn androidx.room.paging.**
