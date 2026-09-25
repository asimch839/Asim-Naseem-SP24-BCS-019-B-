# Salary Calculator Application (Flutter)

A complete, responsive, and modern Flutter application built to collect salary details, calculate tax deductions and net monthly income, and present a detailed breakdown with a clean UI.

---

## 🚀 Features

- **Form Fields & User Inputs**:
  - **Basic Salary**
  - **House Rent Allowance (HRA)**
  - **Medical Allowance**
  - **Travel Allowance**
- **Robust Form Validation**:
  - Ensures no fields are left empty.
  - Ensures inputs are valid positive numeric amounts.
  - Formatted currency inputs with live clear actions.
- **Tax & Income Calculation**:
  - **Gross Salary** = $\text{Basic Salary} + \text{House Rent Allowance} + \text{Medical Allowance} + \text{Travel Allowance}$
  - **Tax Deduction**: Progressive income tax slabs (standard) or configurable flat percentage rate.
  - **Net Monthly Income** = $\text{Gross Salary} - \text{Tax Deduction}$
  - Displays **Tax Deduction first**, followed by **Net Monthly Income** as required.
- **Detailed Salary Breakdown**:
  - Itemized display of Basic Salary, individual allowances, total allowances, Gross Salary, Tax Deduction, and Net Monthly Income.
- **Action Buttons**:
  - **Calculate**: Validates inputs, calculates results, and animates display of result card.
  - **Reset**: Resets all fields, clears errors, and removes result card.
  - **Quick Fill (AppBar)**: Quickly pre-populates sample values for testing.
- **Material 3 Design**:
  - Sleek cards, typography, responsive scroll view, custom color palettes, and full dark mode support.

---

## 📐 Calculation Rules

### Progressive Tax Slabs (Default)
| Gross Monthly Income | Tax Deduction |
| :--- | :--- |
| Up to Rs. 50,000 | 0% (Tax-free) |
| Rs. 50,001 to Rs. 100,000 | 5% of amount exceeding Rs. 50,000 |
| Rs. 100,001 to Rs. 200,000 | Rs. 2,500 + 10% of amount exceeding Rs. 100,000 |
| Above Rs. 200,000 | Rs. 12,500 + 15% of amount exceeding Rs. 200,000 |

*Note: You can also expand "Tax Calculation Settings" to choose a customizable flat tax percentage if desired.*

---

## 📁 Project Architecture

```
lib/
├── main.dart                          # App entry point, MaterialApp, and theme
├── models/
│   └── salary_model.dart             # SalaryInput & SalaryResult data models
├── screens/
│   └── salary_calculator_screen.dart # Main screen with Form, inputs & actions
├── utils/
│   └── tax_calculator.dart           # Tax deduction & currency formatting logic
└── widgets/
    ├── result_card.dart              # Result card showing Tax Deduction & Net Income
    └── salary_input_field.dart       # Reusable validated TextFormField component
test/
├── tax_calculator_test.dart          # Unit tests for tax logic & formatting
└── widget_test.dart                  # End-to-end UI & interaction widget test
```

---

## 🧪 Testing

To execute all unit and widget tests:

```bash
flutter test
```

To run static analysis:

```bash
flutter analyze
```

---

## 📱 How to Run

```bash
flutter run
```
