## **🏗️ Refined PRD for Jules: CarCareApp (Phase 1\)**

### **1\. Objective**

Build a "Zero-to-One" market validation tool for vehicle expense tracking using **Flutter** and **Firebase**. The app must be **Offline-First**, allowing users to log data without a connection, which then syncs once they are back online.

### **2\. Core Tech Stack**

* **Frontend:** Flutter (Mobile).  
* **Backend/Database:** Firebase Firestore (with **Persistence enabled** for offline support).  
* **Authentication:** Firebase Auth (Anonymous or Google Sign-in).  
* **OCR Engine:** `google_ml_kit` for on-device text recognition (to keep it fast and offline-capable).  
* **Location:** `geolocator` package for passive GPS tagging.

### **3\. Feature Specifications**

#### **Feature 1: The "Magic" Fuel & Odometer Log**

* **Action:** A floating action button (FAB) opens a camera view.  
* **OCR Logic:** Automatically scan for numbers representing:  
  * **Odometer** (from the dashboard).  
  * **Total Cost / Volume** (from a petrol receipt).  
* **Manual Fallback:** If OCR fails or payment is **Cash**, a 3-field form appears: Odometer, Liters, and Total Cost.  
* **GPS Tagging:** Every log entry must include `latitude` and `longitude` captured at the time of the save.  
* **Offline Support:** Logs must save to a local Hive/SQFlite database or Firestore local cache immediately.

#### **Feature 2: Expense & Repair Log**

* **Categories:** Repair, Maintenance, Insurance, Misc.  
* **Inputs:** Date, Category, Cost, Note, and Camera (to attach a photo of the bill).

#### **Feature 3: Viral Share Card (The "Shock/Pride" Metric)**

* **Calculation:** Total Cost / Total Kilometers \= **Cost per KM**.  
* **Output:** Generate a high-contrast image card (e.g., *"My car costs Rs. 18/km"*) using the `screenshot` or `render_repaint_boundary` package.  
* **Sharing:** Trigger the native OS share sheet.