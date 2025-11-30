# expo-pixel-sampler

Native pixel color sampling for React Native and Expo. Get the exact color at any coordinate in an image - **instantly and synchronously**.

## Why This Library?

Existing solutions have limitations:
- `react-native-image-colors` - Only extracts **dominant** colors, not specific pixels
- `expo-image-manipulator` - Can crop images but cannot read pixel data
- JavaScript-based solutions - Too slow for real-time use (e.g., color picker drag)

**expo-pixel-sampler** provides:
- ⚡ **Instant** pixel color sampling (~1ms)
- 🎯 **Exact** color at any coordinate
- 🔄 **Synchronous** API for smooth gesture handling
- 📱 Works on **iOS and Android**

## Installation

```bash
npx expo install expo-pixel-sampler
```

Or with npm/yarn:
```bash
npm install expo-pixel-sampler
# or
yarn add expo-pixel-sampler
```

### Requirements

- Expo SDK 49+
- React Native 0.72+
- **Development build required** (does not work with Expo Go)

After installation, rebuild your app:
```bash
npx expo run:ios
# or
npx expo run:android
```

## Usage

### Basic Example

```typescript
import { getPixelColor } from 'expo-pixel-sampler';

// Get the color at a specific point
const hex = getPixelColor(
  imageUri,      // file:// or content:// URI
  x,             // X coordinate in display space
  y,             // Y coordinate in display space  
  displayWidth,  // Width of the displayed image
  displayHeight  // Height of the displayed image
);

console.log(hex); // "#FF5733"
```

### Color Picker Example

```typescript
import React, { useState } from 'react';
import { Image, View, Text } from 'react-native';
import { GestureDetector, Gesture } from 'react-native-gesture-handler';
import { getPixelColor } from 'expo-pixel-sampler';

function ColorPicker({ imageUri }) {
  const [color, setColor] = useState('#FFFFFF');
  const [imageLayout, setImageLayout] = useState({ width: 0, height: 0 });

  const panGesture = Gesture.Pan()
    .onUpdate((event) => {
      // Instant color sampling during drag!
      const hex = getPixelColor(
        imageUri,
        event.x,
        event.y,
        imageLayout.width,
        imageLayout.height
      );
      setColor(hex);
    });

  return (
    <View>
      <GestureDetector gesture={panGesture}>
        <Image
          source={{ uri: imageUri }}
          style={{ width: 300, height: 300 }}
          onLayout={(e) => setImageLayout(e.nativeEvent.layout)}
        />
      </GestureDetector>
      
      <View style={{ backgroundColor: color, padding: 20 }}>
        <Text>{color}</Text>
      </View>
    </View>
  );
}
```

### With Reanimated (Worklets)

Since `getPixelColor` is synchronous, you can call it from the JS thread via `runOnJS`:

```typescript
import { runOnJS } from 'react-native-reanimated';

const sampleColor = (x: number, y: number) => {
  const hex = getPixelColor(imageUri, x, y, width, height);
  // Update your state
};

const gesture = Gesture.Pan()
  .onUpdate((event) => {
    runOnJS(sampleColor)(event.x, event.y);
  });
```

## API Reference

### `getPixelColor(imageUri, x, y, displayWidth, displayHeight): string`

Synchronously samples the pixel color at the given coordinates.

| Parameter | Type | Description |
|-----------|------|-------------|
| `imageUri` | `string` | URI of the image (`file://`, `content://`, or `http://`) |
| `x` | `number` | X coordinate relative to displayed image |
| `y` | `number` | Y coordinate relative to displayed image |
| `displayWidth` | `number` | Width of the displayed image in pixels |
| `displayHeight` | `number` | Height of the displayed image in pixels |

**Returns:** Hex color string (e.g., `"#FF5733"`)

### `getPixelColorAsync(imageUri, x, y, displayWidth, displayHeight): Promise<string>`

Async version of `getPixelColor`. Use this if you prefer Promise-based APIs.

## How It Works

### iOS (Swift)
- Loads the image and normalizes orientation
- Uses `CGContext` to sample the exact pixel
- Caches images for repeated sampling

### Android (Kotlin)
- Loads the image as a `Bitmap`
- Uses `Bitmap.getPixel()` for sampling
- Caches bitmaps for performance

Both platforms handle coordinate transformation from display space to image space automatically.

## Performance

| Operation | Time |
|-----------|------|
| First sample (cold cache) | ~50-100ms |
| Subsequent samples (cached) | ~1-2ms |

The library caches up to 5 images. Older images are evicted when the cache is full.

## Limitations

- **Requires native build** - Does not work with Expo Go
- **Large images** - Very large images (8K+) may be slow to load initially
- **Animated images** - Only samples the first frame of GIFs

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT

