# Implementation Options: Logic Layer

We need to build the "Brain" of the application first:
1.  Fetch contacts from Google.
2.  Store them locally / in a temporary DB.
3.  Process/Fix the numbers.
4.  Push changes back (optional for now).

Here are 3 approaches to build this Logic Layer before touching Android.

## Option A: Python Script (Recommended for Learning)
We build a standalone Python script to handle the logic.
*   **Pros**:
    *   Python is excellent for data manipulation and testing logic.
    *   Very easy to use with Google APIs.
    *   Fastest way to prototype the "algorithm" for fixing numbers.
*   **Cons**:
    *   The code is not directly copy-pasteable to Android (Kotlin/Java). You will have to rewrite the logic in Kotlin later.
*   **Stack**: Python 3, `google-api-python-client`, SQLite (built-in).

## Option B: Kotlin Multiplatform (KMP) or Pure Kotlin (JVM)
We write the logic in Kotlin right now, running on your computer (JVM).
*   **Pros**:
    *   **Reuse**: The code you write here *is* the code that goes into the Android app. 100% reusable.
    *   Good practice for Android development.
*   **Cons**:
    *   Slightly harder setup (Gradle/IntelliJ) compared to a simple Python script.
*   **Stack**: Kotlin, SQLite (via Exposed or SQLDelight), Google Java Client Lib.

## Option C: Node.js / Typescript
We build the backend logic in Node.js.
*   **Pros**:
    *   Good if you want to learn Web Backend development specifically.
*   **Cons**:
    *   Not reusable for Android (unless using React Native).
    *   Different paradigm than what you wanted (Mobile App).

### My Recommendation
Since you want to "simulate a professional work environment" and your end goal is an **Android App**:

I recommend **Option B (Kotlin)** if you are comfortable with slightly more setup. It simulates the real workflow: writing the "Domain Logic" in the actual language of the app, ensuring it works, and then just wrapping a UI around it.

If you just want to solve the problem logic *fast* and don't mind rewriting it later, choose **Option A (Python)**.
