<template>
  <div>
    <NuxtLayout v-if="route.path !== '/login'" name="default">
      <NuxtPage />
    </NuxtLayout>
    <NuxtPage v-else />
  </div>
</template>

<script setup lang="ts">
import { useSupabaseUser } from '#imports';
import { useRoute, useRouter } from 'vue-router';

const user = useSupabaseUser();
const router = useRouter();
const route = useRoute();

// Watch for user changes and redirect if not logged in
watch(user, (newUser) => {
  if (!newUser && router.currentRoute.value.path !== '/login' && router.currentRoute.value.path !== '/confirm') {
    router.push('/login');
  }
}, { immediate: true }); // Run immediately on component mount
</script>
