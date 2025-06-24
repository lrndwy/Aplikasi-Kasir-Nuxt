<template>
  <div
    class="flex flex-col items-center justify-center w-full h-48 border-2 border-gray-300 border-dashed rounded-lg cursor-pointer bg-gray-50 dark:hover:bg-gray-800 dark:bg-gray-700 hover:bg-gray-100 dark:border-gray-600 dark:hover:border-gray-500"
    @dragover.prevent="handleDragOver"
    @dragleave.prevent="handleDragLeave"
    @drop.prevent="handleDrop"
    @click="handleClick"
  >
    <input
      ref="fileInput"
      type="file"
      accept="image/*"
      class="hidden"
      @change="handleFileChange"
    />
    <div v-if="imageUrl" class="relative w-full h-full">
      <img :src="imageUrl" alt="Preview" class="object-cover w-full h-full rounded-lg" />
      <Button
        type="button"
        variant="destructive"
        size="sm"
        class="absolute top-2 right-2"
        @click.stop="removeImage"
      >
        Hapus
      </Button>
    </div>
    <div v-else class="flex flex-col items-center justify-center pt-5 pb-6">
      <svg
        class="w-8 h-8 mb-4 text-gray-500 dark:text-gray-400"
        aria-hidden="true"
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 20 16"
      >
        <path
          stroke="currentColor"
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M13 13h3a3 3 0 0 0 0-6h-.025A5.56 5.56 0 0 0 16 6.5 5.5 5.5 0 0 0 5.207 5.021C5.137 5.017 5.071 5 5 5a4 4 0 0 0 0 8h2.167M10 15V6m0 0L7.5 8.5M10 6l2.5 2.5"
        />
      </svg>
      <p class="mb-2 text-sm text-gray-500 dark:text-gray-400">
        <span class="font-semibold">Klik untuk mengunggah</span> atau seret dan lepas
      </p>
      <p class="text-xs text-gray-500 dark:text-gray-400">SVG, PNG, JPG or GIF (MAX. 800x400px)</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue';
import { Button } from '@/components/ui/button';

const props = defineProps<{
  modelValue: File | null;
  initialImageUrl?: string | null;
}>();

const emit = defineEmits(['update:modelValue', 'remove']);

const fileInput = ref<HTMLInputElement | null>(null);
const imageUrl = ref<string | null>(props.initialImageUrl || null);

watch(() => props.initialImageUrl, (newUrl) => {
  if (newUrl && newUrl !== imageUrl.value) {
    imageUrl.value = newUrl;
  } else if (!newUrl && imageUrl.value && !props.modelValue) {
    // If initialImageUrl becomes null and no file is selected, clear preview
    imageUrl.value = null;
  }
}, { immediate: true });

watch(() => props.modelValue, (newFile) => {
  if (newFile) {
    imageUrl.value = URL.createObjectURL(newFile);
  } else if (!props.initialImageUrl) {
    imageUrl.value = null;
  }
});

const handleFileChange = (event: Event) => {
  const target = event.target as HTMLInputElement;
  if (target.files && target.files[0]) {
    const file = target.files[0];
    emit('update:modelValue', file);
  } else {
    emit('update:modelValue', null);
  }
};

const handleDragOver = (event: DragEvent) => {
  event.currentTarget?.classList.add('border-blue-500', 'bg-blue-50');
};

const handleDragLeave = (event: DragEvent) => {
  event.currentTarget?.classList.remove('border-blue-500', 'bg-blue-50');
};

const handleDrop = (event: DragEvent) => {
  event.currentTarget?.classList.remove('border-blue-500', 'bg-blue-50');
  if (event.dataTransfer?.files && event.dataTransfer.files[0]) {
    const file = event.dataTransfer.files[0];
    emit('update:modelValue', file);
  }
};

const handleClick = () => {
  fileInput.value?.click();
};

const removeImage = () => {
  imageUrl.value = null;
  if (fileInput.value) {
    fileInput.value.value = '';
  }
  emit('update:modelValue', null);
  emit('remove');
};
</script>

<style scoped>
/* Add any specific styles here if needed */
</style>
