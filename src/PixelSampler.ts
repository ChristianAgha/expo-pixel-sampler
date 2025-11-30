import { requireNativeModule } from 'expo-modules-core';

// Define the native module interface
interface PixelSamplerModule {
  getPixelColor(
    imageUri: string,
    x: number,
    y: number,
    displayWidth: number,
    displayHeight: number
  ): string;
  
  getPixelColorAsync(
    imageUri: string,
    x: number,
    y: number,
    displayWidth: number,
    displayHeight: number
  ): Promise<string>;
}

// Load the native module
const NativeModule = requireNativeModule<PixelSamplerModule>('PixelSampler');

/**
 * Get pixel color at coordinates - SYNCHRONOUS (instant!)
 * @param imageUri - URI of the image (file:// path)
 * @param x - X coordinate in display space
 * @param y - Y coordinate in display space
 * @param displayWidth - Width of the displayed image
 * @param displayHeight - Height of the displayed image
 * @returns Hex color string (e.g., "#FF5733")
 */
export function getPixelColor(
  imageUri: string,
  x: number,
  y: number,
  displayWidth: number,
  displayHeight: number
): string {
  return NativeModule.getPixelColor(imageUri, x, y, displayWidth, displayHeight);
}

/**
 * Get pixel color at coordinates - ASYNC version
 */
export async function getPixelColorAsync(
  imageUri: string,
  x: number,
  y: number,
  displayWidth: number,
  displayHeight: number
): Promise<string> {
  return NativeModule.getPixelColorAsync(imageUri, x, y, displayWidth, displayHeight);
}

