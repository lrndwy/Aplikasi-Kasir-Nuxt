<template>
  <div class="flex items-center justify-center min-h-screen bg-gray-100 dark:bg-gray-900">
    <div
      class="w-full max-w-md p-8 space-y-6 bg-white rounded-lg shadow-md dark:bg-gray-800"
    >
      <h2 class="text-2xl font-bold text-center text-gray-900 dark:text-white">
        {{ isRegister ? "Daftar Akun Baru" : "Masuk ke Aplikasi Kasir" }}
      </h2>

      <form @submit.prevent="handleAuth" class="space-y-4">
      <div v-if="isRegister">
          <Label class="mb-2" for="fullName">Nama Lengkap</Label>
          <Input
            id="fullName"
            v-model="fullName"
            type="text"
            placeholder="Nama Lengkap Anda"
          />
        </div>
        <div>
          <Label for="email" class="mb-2">Email</Label>
          <Input
            id="email"
            v-model="email"
            type="email"
            placeholder="email@example.com"
            required
          />
        </div>
        <div>
          <Label for="password" class="mb-2">Password</Label>
          <Input
            id="password"
            v-model="password"
            type="password"
            placeholder="********"
            required
          />
        </div>


        <Button type="submit" class="w-full" :disabled="loading">
          <span v-if="loading">Memproses...</span>
          <span v-else>{{ isRegister ? "Daftar" : "Masuk" }}</span>
        </Button>
      </form>

      <div class="text-center text-sm text-gray-600 dark:text-gray-400">
        <p v-if="isRegister">
          Sudah punya akun?
          <Button variant="link" @click="isRegister = false" class="p-0 h-auto"
            >Masuk</Button
          >
        </p>
        <p v-else>
          Belum punya akun?
          <Button variant="link" @click="isRegister = true" class="p-0 h-auto"
            >Daftar Sekarang</Button
          >
        </p>
      </div>

      <div v-if="errorMessage" class="text-red-500 text-center text-sm">
        {{ errorMessage }}
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  layout: false,
});
definePageMeta({
  title: 'Login - Aplikasi Kasir'
})
import { ref } from "vue";
import { useRouter } from "vue-router";
import { useSupabaseClient } from "#imports";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

const supabase = useSupabaseClient();
const router = useRouter();

const email = ref("");
const password = ref("");
const fullName = ref("");
const isRegister = ref(false);
const loading = ref(false);
const errorMessage = ref("");

const handleAuth = async () => {
  loading.value = true;
  errorMessage.value = "";

  try {
    if (isRegister.value) {
      const { error } = await supabase.auth.signUp({
        email: email.value,
        password: password.value,
        options: {
          data: {
            full_name: fullName.value,
          },
        },
      });
      if (error) throw error;
      router.push("/"); // Redirect to confirm page after registration
    } else {
      const { error } = await supabase.auth.signInWithPassword({
        email: email.value,
        password: password.value,
      });
      if (error) throw error;
      router.push("/"); // Redirect to home page after successful login
    }
  } catch (error: any) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
};

// Redirect if user is already logged in
onMounted(async () => {
  const {
    data: { session },
  } = await supabase.auth.getSession();
  if (session) {
    router.push("/");
  }
});
</script>

<style scoped>
/* No specific styles needed as @nuxt/ui and shadcn-nuxt handle styling */
</style>
