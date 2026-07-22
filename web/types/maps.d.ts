declare module "react-simple-maps" {
  import type { ComponentProps, ReactNode } from "react";

  export type GeographyProps = {
    geography: unknown;
    style?: Record<string, Record<string, string | number>>;
    tabIndex?: number;
    role?: string;
    "aria-label"?: string;
    className?: string;
    onMouseEnter?: () => void;
    onMouseLeave?: () => void;
    onFocus?: () => void;
    onBlur?: () => void;
    onClick?: () => void;
    onKeyDown?: (event: React.KeyboardEvent) => void;
  };

  export type GeographiesProps = {
    geography: unknown;
    children: (context: {
      geographies: Array<{
        rsmKey: string;
        properties: Record<string, unknown> | null;
      }>;
    }) => ReactNode;
  };

  export type ComposableMapProps = ComponentProps<"svg"> & {
    projection?: string;
    projectionConfig?: Record<string, number | [number, number]>;
  };

  export function ComposableMap(props: ComposableMapProps): JSX.Element;
  export function Geographies(props: GeographiesProps): JSX.Element;
  export function Geography(props: GeographyProps): JSX.Element;
}
