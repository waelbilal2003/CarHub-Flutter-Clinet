---
name: Premium Automotive Exchange
colors:
  surface: '#f7f9fc'
  surface-dim: '#d8dadd'
  surface-bright: '#f7f9fc'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f7'
  surface-container: '#eceef1'
  surface-container-high: '#e6e8eb'
  surface-container-highest: '#e0e3e6'
  on-surface: '#191c1e'
  on-surface-variant: '#3d4a3e'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f4'
  outline: '#6d7b6d'
  outline-variant: '#bccabb'
  surface-tint: '#006d37'
  primary: '#006d37'
  on-primary: '#ffffff'
  primary-container: '#00b761'
  on-primary-container: '#00401e'
  inverse-primary: '#4de085'
  secondary: '#515f78'
  on-secondary: '#ffffff'
  secondary-container: '#d2e0fe'
  on-secondary-container: '#55637d'
  tertiary: '#555f6f'
  on-tertiary: '#ffffff'
  tertiary-container: '#96a0b2'
  on-tertiary-container: '#2d3746'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#6dfe9e'
  primary-fixed-dim: '#4de085'
  on-primary-fixed: '#00210d'
  on-primary-fixed-variant: '#005228'
  secondary-fixed: '#d6e3ff'
  secondary-fixed-dim: '#b9c7e4'
  on-secondary-fixed: '#0d1c32'
  on-secondary-fixed-variant: '#39475f'
  tertiary-fixed: '#d9e3f7'
  tertiary-fixed-dim: '#bdc7da'
  on-tertiary-fixed: '#121c2a'
  on-tertiary-fixed-variant: '#3d4757'
  background: '#f7f9fc'
  on-background: '#191c1e'
  surface-variant: '#e0e3e6'
typography:
  headline-xl:
    fontFamily: Readex Pro
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 48px
  headline-lg:
    fontFamily: Readex Pro
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 36px
  headline-md:
    fontFamily: Readex Pro
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 30px
  body-lg:
    fontFamily: Readex Pro
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Readex Pro
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Readex Pro
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-bold:
    fontFamily: Readex Pro
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-sm:
    fontFamily: Readex Pro
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  headline-lg-mobile:
    fontFamily: Readex Pro
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 32px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-padding: 20px
  card-gap: 16px
  section-margin: 32px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
---

## Brand & Style

The design system is engineered for a premium, automotive-centric marketplace. It prioritizes **trust, efficiency, and mechanical precision**. The visual narrative balances the industrial nature of car parts with a high-end service experience, ensuring users feel confident when managing high-value transactions like repair bidding.

The style is **Corporate Modern with Layered Elevation**. It utilizes a sophisticated "Dark Mode First" influence for headers and navigation to evoke a premium "night-drive" aesthetic, while maintaining high-legibility "Light Mode" surfaces for complex data like spare part listings and bidding tables. The aesthetic is clean and high-tech, characterized by:
- **Precision:** Perfect alignment and generous whitespace.
- **Velocity:** Subtle horizontal gradients and streamlined iconography.
- **Reliability:** A robust, deep color palette anchored by high-contrast emerald actions.

## Colors

The palette is optimized for an RTL (Right-to-Left) Arabic interface, ensuring visual weight is balanced across the screen.

- **Vibrant Emerald (#00B761):** The primary engine of the UI. Used exclusively for conversion points, "Accept Bid" actions, and success states. It represents growth and movement.
- **Deep Navy (#0A192F):** Used for top navigation, primary headers, and high-level containers. It provides a grounded, professional foundation that contrasts sharply with content.
- **Soft Grey (#F5F7FA):** The global canvas. This off-white background reduces eye strain and allows white content cards to pop with subtle depth.
- **Muted Grey (#8A94A6):** Dedicated to metadata, secondary labels, and inactive states to maintain a clear visual hierarchy.

## Typography

The typography system uses **Readex Pro** for its exceptional legibility in Arabic and its modern, geometric construction.

- **Hierarchy:** Titles are always bold to anchor the eye in an RTL flow. 
- **Rhythm:** Generous line-heights (1.5x) are maintained to accommodate Arabic diacritics and prevent visual crowding in dense lists.
- **Alignment:** All text is right-aligned by default. Numbers (prices, part IDs) should utilize tabular lining to ensure vertical alignment in bidding tables.

## Layout & Spacing

This design system follows a strict **8pt grid** to ensure mathematical harmony across all screen sizes.

- **Mobile First:** A fluid grid with 20px side margins. Content cards typically span the full available width minus margins.
- **RTL Flow:** Layouts are mirrored; progress bars, carousels, and navigation icons flow from right to left.
- **Density:** High whitespace in the bidding and spare parts marketplace prevents the interface from feeling "heavy" or "industrial," keeping it accessible for everyday users.

## Elevation & Depth

Visual hierarchy is established through a **layered surface model**:

1.  **Floor (Level 0):** Soft Grey (#F5F7FA) background.
2.  **Card (Level 1):** White (#FFFFFF) surfaces with a 16px border radius. These use a very soft, diffused ambient shadow: `0px 4px 20px rgba(10, 25, 47, 0.05)`.
3.  **Interactive (Level 2):** Primary buttons and active states. These may use a slight lift on hover/active state to indicate interactivity.
4.  **Hero/Header:** Deep Navy gradients are used for top-level navigation areas to create a "canopy" effect over the content cards.

## Shapes

The shape language is **Rounded**, reflecting the ergonomic curves of modern automotive design.

- **Standard Radius:** 16px (rounded-lg) for all primary content cards and containers.
- **Pill Shapes:** Reserved exclusively for Primary Buttons and Search Bars to differentiate them from static content.
- **Iconography:** 24px line-style icons with a 1.5px or 2px stroke weight for a clean, technical appearance.

## Components

- **Primary Buttons:** Emerald (#00B761) pill-shaped buttons with Bold White Readex Pro text. Use a subtle horizontal gradient (Emerald to a slightly darker shade) for a 2025 "glassy" feel.
- **Bidding Cards:** White background, 16px radius, containing high-contrast status tags (e.g., "Active Bid" in Emerald, "Expired" in Muted Grey).
- **Input Fields:** Soft Grey (#F5F7FA) fills with 8px radius and subtle 1px borders in Muted Grey. Focus states should use an Emerald stroke.
- **Chips/Badges:** Used for car categories (e.g., Engine, Suspension). These should be low-contrast (White with a thin Grey border) to avoid competing with primary buttons.
- **Bidding Progress:** A custom component showing the timeline of a repair bid, utilizing the 8pt grid for consistent spacing between milestones.
- **Product Gallery:** Squared-off corners for images within the 16px card container to maximize image area for part inspections.