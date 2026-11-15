# MELSAVA Design System

## Brand Identity & Aesthetic
MELSAVA is an activity-first social discovery platform designed to feel like a modern, warm editorial lifestyle publication—never a conventional swipe-based dating interface.

### Brand Values
- **Warm & Welcoming**: Grounded in natural, soothing tones.
- **Inclusive & Human**: Equal footing for deep friendship, activity partners, and intentional dating.
- **Thoughtful & Premium**: Generous whitespace, refined typography, and tactile surface styling.

---

## Color Palette

The color system is derived from natural, warm hues that establish comfort and trust:

| Token Name | Hex Code | Role | Description |
|---|---|---|---|
| **Warm Ivory** | `#F7F3EF` | Surface / Canvas | Primary background tone for screens and scaffold |
| **Deep Plum** | `#292332` | Primary / Headings | Bold accent, primary buttons, high-emphasis text |
| **Mauve** | `#795B91` | Primary Accent / Interactive | Key active icons, links, secondary interactive elements |
| **Soft Coral** | `#E9A18B` | Warm Highlight | Badges, tags, activity category accents |
| **Sage** | `#DCE8DF` | Calming Accent | Success states, nature/fitness tags, soft borders |
| **White** | `#FFFFFF` | Card / Dialog Fill | Elevated surfaces, cards, and modal sheets |
| **Muted Text** | `#77717A` | Secondary Typography | Supporting captions, metadata, inactive icons |
| **Error** | `#D32F2F` | Feedback | Danger/error alerts and form validation |

---

## Typography

The typography pairs an expressive geometric sans-serif for headings with a legible, neutral sans-serif for body copy.

- **Headings & Titles**: `Manrope` (Weights: 600 SemiBold, 700 Bold, 800 ExtraBold)
- **Body & Captions**: `Inter` (Weights: 400 Regular, 500 Medium, 600 SemiBold)

### Type Scale

| Style | Font Family | Size | Weight | Line Height | Tracking |
|---|---|---|---|---|---|
| Display Large | Manrope | 32px | Bold (700) | 40px | -0.5px |
| Display Medium | Manrope | 28px | Bold (700) | 36px | -0.25px |
| Headline Large | Manrope | 24px | SemiBold (600) | 32px | 0px |
| Headline Medium| Manrope | 20px | SemiBold (600) | 28px | 0px |
| Title Large | Manrope | 18px | SemiBold (600) | 24px | 0.15px |
| Title Medium | Manrope | 16px | SemiBold (600) | 22px | 0.15px |
| Body Large | Inter | 16px | Regular (400) | 24px | 0.5px |
| Body Medium | Inter | 14px | Regular (400) | 20px | 0.25px |
| Body Small | Inter | 12px | Regular (400) | 16px | 0.4px |
| Label Large | Inter | 14px | Medium (500) | 20px | 0.1px |
| Label Small | Inter | 11px | Medium (500) | 16px | 0.5px |

---

## Spacing & Layout Grid

- **Base Unit**: 8-point spatial grid (`4px`, `8px`, `16px`, `24px`, `32px`, `48px`, `64px`).
- **Screen Padding**: Standard horizontal padding is `20px` (or `24px` on tablet/larger screens).
- **Minimum Touch Target**: 48 × 48 logical pixels for all interactive targets.
- **Card Corners**: `16px` to `22px` border radius with subtle, low-opacity drop shadows (`0 4px 16px rgba(41, 35, 50, 0.06)`).
- **Button Corners**: `14px` to `16px` pill/rounded rectangles.

---

## Reusable Component Library

1. **Buttons**:
   - `PrimaryButton`: Filled Deep Plum background with White text, full-width or compact, with built-in loading indicator.
   - `SecondaryButton`: Outlined Mauve or Soft Coral border with transparent background.
   - `TextActionButton`: Unframed text button for skips, secondary links, and auxiliary actions.
2. **Form Controls**:
   - `CustomTextField`: 14px radius, Warm Ivory/White background, subtle border, floating or inline label.
3. **Experience Elements**:
   - `ExperienceCard`: Image cover, category badge, title, date/time chip, spots-left indicator, host preview.
   - `CategoryChip`: Horizontal scrolling filter chip with category icon and muted background.
   - `ParticipantCard`: Non-invasive avatar, first name, and common interest pills.
4. **Connection & Chat**:
   - `ConnectionCard`: Mutual connection banner, mutual intention indicator ("Friendship", "Dating"), start chat CTA.
   - `MessageBubble`: Deep Plum for user messages, White/Warm Ivory for received messages.
5. **Feedback & States**:
   - `EmptyStateWidget`: Warm illustration/icon, contextual heading, and encouraging action button.
   - `LoadingWidget`: Branded Mauve spinner.
   - `AppErrorWidget`: Friendly error explanation with retry button.
   - `ConfirmationDialog` & `ReportDialog`: Standardized modal sheets for critical decisions.

---

## Brand Logo & Symbol
- **Abstract Converging Geometry**: 3 distinct curved nodes that sweep inward and converge into a unified central point, forming a subtle silhouette of an "M".
- **Meaning**: Distinct paths crossing at shared moments and continuing together.
