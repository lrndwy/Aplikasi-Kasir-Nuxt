declare module '*.vue' {
  import type { DefineComponent } from 'vue'
  const component: DefineComponent<{}, {}, any>
  export default component
}

declare module '@/components/ui/image-upload' {
  export { ImageUpload } from '@/components/ui/image-upload/ImageUpload.vue';
}
