<template>
  <div class="webcam-container">
    <video ref="videoElement" autoplay class="w-full h-auto rounded-md"></video>
    <canvas ref="canvasElement" style="display: none;"></canvas>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, defineExpose } from 'vue';

const videoElement = ref<HTMLVideoElement | null>(null);
const canvasElement = ref<HTMLCanvasElement | null>(null);
let stream: MediaStream | null = null;

const props = defineProps({
  width: {
    type: Number,
    default: 560,
  },
  height: {
    type: Number,
    default: 420,
  },
  mirror: {
    type: Boolean,
    default: true,
  },
});

onMounted(async () => {
  try {
    stream = await navigator.mediaDevices.getUserMedia({ video: true });
    if (videoElement.value) {
      videoElement.value.srcObject = stream;
      videoElement.value.play();
    }
  } catch (err) {
    console.error("Error accessing webcam:", err);
    alert("Gagal mengakses kamera. Pastikan Anda memberikan izin kamera.");
  }
});

onBeforeUnmount(() => {
  if (stream) {
    stream.getTracks().forEach(track => track.stop());
  }
});

const capture = (): string | null => {
  if (videoElement.value && canvasElement.value) {
    const video = videoElement.value;
    const canvas = canvasElement.value;

    canvas.width = props.width;
    canvas.height = props.height;

    const context = canvas.getContext('2d');
    if (context) {
      // Apply mirroring if enabled
      if (props.mirror) {
        context.translate(canvas.width, 0);
        context.scale(-1, 1);
      }
      context.drawImage(video, 0, 0, canvas.width, canvas.height);
      return canvas.toDataURL('image/jpeg');
    }
  }
  return null;
};

defineExpose({
  capture,
});
</script>

<style scoped>
.webcam-container video {
  transform: scaleX(v-bind(mirror ? -1 : 1));
}
</style>
