<template>
  <div class="flex items-center justify-center min-h-screen bg-gray-100 dark:bg-gray-900">
    <div v-if="pageLoading" class="text-center text-gray-500 dark:text-gray-400 mt-8">
      Memuat halaman konfirmasi...
    </div>
    <div
      v-else
      class="w-full max-w-md p-8 space-y-6 bg-white rounded-lg shadow-md dark:bg-gray-800 text-center"
    >
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">
        Konfirmasi Email Anda
      </h2>
      <p class="text-gray-700 dark:text-gray-300">
        Terima kasih telah mendaftar! Silakan cek kotak masuk email Anda untuk tautan
        konfirmasi. Setelah mengklik tautan tersebut, Anda akan otomatis masuk ke
        aplikasi.
      </p>
      <p class="text-sm text-gray-500 dark:text-gray-400">
        Jika Anda tidak menerima email, periksa folder spam atau coba daftar ulang.
      </p>
      <Button @click="router.push('/login')" class="mt-4"
        >Kembali ke Halaman Login</Button
      >
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from "vue"; // Import onMounted
import { useRouter } from "vue-router";
import { useSupabaseClient } from "#imports";
import { Button } from "@/components/ui/button";

const supabase = useSupabaseClient();
const router = useRouter();

const pageLoading = ref(true); // New ref for overall page loading

onMounted(async () => {
  pageLoading.value = true; // Start loading
  try {
    const {
      data: { session },
      error,
    } = await supabase.auth.getSession();

    if (error) {
      console.error("Error getting session:", error.message);
      // Optionally redirect to an error page or login
      router.push("/login");
      return;
    }

    if (session) {
      // User is already logged in (e.g., after email confirmation redirect)
      router.push("/");
    }
    // If no session, stay on this page, waiting for email confirmation
  } finally {
    pageLoading.value = false; // End loading
  }
});
</script>

<style scoped>
/* No specific styles needed as @nuxt/ui and shadcn-nuxt handle styling */
</style>
