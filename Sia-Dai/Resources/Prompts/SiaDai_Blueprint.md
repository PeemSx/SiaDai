# SiaDai AI Build Prompts

## Core Context (Send this with every new chat)
> Context: You are an expert iOS developer strictly adhering to Apple's Human Interface Guidelines. We are building a standalone iOS 17 app called "SiaDai" using SwiftUI and SwiftData. It is an anti-food-waste tracker.

Everytime when you write any code you should take a look at those PDF files in Sources folder to learn how to implement them properly style to avoid complicated code.
---

## Step 1: Data Model
**Goal:** Setup SwiftData models.
**Prompt to Copy:**
> Please write the complete SwiftData @Model classes for this app. We need:

FoodItem:

id: UUID

name: String (e.g., "Organic Baby Spinach")

imageData: Data? (To store the user's photo locally)

purchaseValue: Double (e.g., 5.00)

amount: Double (e.g., 250)

unit: String (e.g., "g")

dateAdded: Date

expiryDate: Date

status: String/Enum (Options: "Tracking", "Eaten", "Trashed")

Please provide the code for this model, and set up a simple ModelContainer preview helper so we can test our UI with sample data (e.g., Salmon, Milk, Spinach, Apples).

---

## Step 2: Main Watchlist
**Goal:** Build the UI for the main grid.
**Prompt to Copy:**
> Create a SwiftUI view called WatchlistView.

Layout:

Header: Text "YOUR INVENTORY" and large bold title "Watchlist". Top right has a small pink pill badge saying "Waste Jar: $15 lost".

Body: A LazyVGrid with 2 columns displaying active FoodItems.

Overlay: A large prominent brand-green floating action button (FAB) with a "+" icon at the bottom center.

Bottom Tab bar with items: "Watch", "Add", "Bin".

The Grid Cards:
Each card needs to show the image filling the top half, and a white bottom half with the Item Name and expiry date text.
Crucial Logic: Add a border modifier to the card container. If expiryDate is today, border is Crimson Red. If in 1-3 days, border is Amber Yellow. If > 3 days, border is Emerald Green.

---

## Step 3: The Add/Edit Modals
**Goal:**
**Prompt to copy:**
> Create a SwiftUI view called AddFoodView. 
Layout:

Top: A large placeholder rectangle that uses PhotosPicker to let the user select an image. Once selected, show the image.

Middle: A clean TextField for "VALUE ($)", and a split section for "AMOUNT" with a text field and a Picker for units (g, lbs, pack).

Expiry Section: Instead of a complex DatePicker, build three large circular/pill toggle buttons horizontally: "3 Days", "5 Days", "1 Week". When tapped, this sets the expiryDate variable.

Bottom: A large green prominent button "Save to Watchlist" that inserts the item into the SwiftData context and dismisses the sheet.

--- 

## Step 4: Recipe & Action Detail Screen
**Goal:**
**Prompt to copy:**
> Create a SwiftUI view called ItemDetailView that takes a FoodItem as a parameter.

Layout:

Top: Large image of the food, with a red text overlay "Expires TODAY!" and the name/weight below it.

Action Area: Two large side-by-side buttons. Left is Green: "I Ate It (Save $X)". Right is Grey: "Trash It (Lose $X)". Tapping these changes the item's status in SwiftData to "Eaten" or "Trashed".

Below: A horizontal ScrollView titled "Rescue Recipes" showing cards (Image, Recipe Name, quick details). For now, use a static array of mock recipes.

---

## Step 5: Waste Jar Analytics
**Goal:**
**Prompt to copy:**
> Create a SwiftUI view called WasteJarView.

Layout:

Header: Large bold text showing the total $45.00 (calculate this by summing the purchaseValue of all FoodItems where status == "Trashed").

Chart: Import Charts. Create a BarChart (BarMark) titled "MONEY LOST (LAST 4 WEEKS)". X-axis is Wk 01 to Wk 04. Y-axis is monetary value. The bars should be green and show the exact amount on top of the bar.

Bottom: A List of "Most Trashed Items" showing the food icon, name, and total cost lost.

---

Context: Act as an expert iOS UI/UX designer strictly following Apple's Human Interface Guidelines. We are designing a standalone Home screen for the SiaDai anti-food waste app. The design must be modern, ultra-minimalist, and clean.

1. Home Header & Navigation:

At the top of the screen, place a modern navigation bar. On the left, a profile icon. In the center, the app name "SiaDai". On the right, a notifications icon.

Below the nav bar, add a large bold title: "Home" or "Priorities This Week". Place a smaller subtitle below it: "Prevent $X from being wasted."

2. Priorities Watchlist (Core Feature - Expedited Inventory):

Create a section titled "Priorities Watchlist". It should be a vertical list of 3-4 modern, high-priority food item cards pulled directly from the Watchlist inventory. Use clean photo cards like in without heavy shadows.

Each detailed card should include:

High-quality food photo (Salmon, Spinach, Milk).

Item Name, amount (e.g., 250g), and Value (e.g., $5.00).

Clear Expiry Date (e.g., "TODAY", "In 1 Day").

URGENCY CODING: Maintain the traffic light colored borders on the card: Crimson Red (Expires Today!), Amber Yellow (Eat Soon), Emerald Green (Fresh). Follow the exact color logic from the "Traffic Light Urgency" concept.

3. prioritized Actions:

CRUCIAL DETAIL: On every ingredient card in this Priority Watchlist, add two distinct, large, prominent action buttons at the bottom:

"I Ate It (Save $X)" (Emerald Green button with checkmark icon).

"Trash It (Lose $X)" (Grey button with trash icon).

(Optional) A secondary action "View Recipe".

4. Rescue Recipes:

Below the priority items list, add a section titled "Rescue Recipes". Use a horizontal, scrollable carousel of recipe cards. Each card should feature:

Beautiful, appetizing photo of the finished dish.

Recipe name (e.g., "Spinach Omelette").

Tag indicating which tracked ingredient it uses (e.g., "Inventory Match").

Preparation details: Prep time, cook time.

Difficulty: Easy. Servings: 1.

5. Bottom Tab Bar:

At the very bottom, place the standard SiaDai bottom tab bar from (Watch, Add, Bin).

6. Visual Aesthetic:

Maintain the ultra-minimalist, clean design of the existing SiaDai screens. Use ample white space, high-quality photography, and clear typographic hierarchy. The overall feeling should be premium, high-tech, and trustworthy.