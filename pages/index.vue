<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-4">
    <div class="w-full space-y-8">
      <h1 class="text-4xl font-bold text-gray-900 dark:text-white mb-6">
        Dashboard Aplikasi Kasir
      </h1>

      <div v-if="user" class="space-y-8">
        <!-- Overview Section -->
        <section class="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
          <h2 class="text-2xl font-semibold text-gray-900 dark:text-white mb-4">
            Overview
          </h2>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <!-- Card 1: Total Penjualan (Placeholder) -->
            <div class="bg-blue-50 dark:bg-blue-900 p-4 rounded-md shadow-sm">
              <p class="text-sm text-blue-700 dark:text-blue-300">
                Total Penjualan Hari Ini
              </p>
              <p class="text-2xl font-bold text-blue-800 dark:text-blue-200 mt-1">Rp 0</p>
            </div>
            <!-- Card 2: Jumlah Transaksi (Placeholder) -->
            <div class="bg-green-50 dark:bg-green-900 p-4 rounded-md shadow-sm">
              <p class="text-sm text-green-700 dark:text-green-300">Jumlah Transaksi</p>
              <p class="text-2xl font-bold text-green-800 dark:text-green-200 mt-1">0</p>
            </div>
            <!-- Card 3: Produk Terjual (Placeholder) -->
            <div class="bg-yellow-50 dark:bg-yellow-900 p-4 rounded-md shadow-sm">
              <p class="text-sm text-yellow-700 dark:text-yellow-300">Produk Terjual</p>
              <p class="text-2xl font-bold text-yellow-800 dark:text-yellow-200 mt-1">
                0
              </p>
            </div>
            <!-- Card 4: Pengguna Aktif (Placeholder) -->
            <div class="bg-red-50 dark:bg-red-900 p-4 rounded-md shadow-sm">
              <p class="text-sm text-red-700 dark:text-red-300">Pengguna Aktif</p>
              <p class="text-2xl font-bold text-red-800 dark:text-red-200 mt-1">1</p>
            </div>
          </div>
        </section>

        <!-- User Profile and Role Access Section -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <section class="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6 space-y-4">
            <h2 class="text-2xl font-semibold text-gray-900 dark:text-white">
              Informasi Profil Anda:
            </h2>
            <p class="text-gray-700 dark:text-gray-300">
              <strong>Email:</strong> {{ user.email }}
            </p>
            <p class="text-gray-700 dark:text-gray-300">
              <strong>Nama Lengkap:</strong>
              {{ userProfile?.full_name || "Belum diatur" }}
            </p>
            <p class="text-gray-700 dark:text-gray-300">
              <strong>Peran:</strong>
              <span class="capitalize">{{ userProfile?.role || "Tidak Diketahui" }}</span>
            </p>

            <div
              v-if="userProfile?.role === 'admin' || userProfile?.role === 'manager'"
              class="mt-6 p-4 bg-blue-50 dark:bg-blue-900 rounded-md"
            >
              <h3 class="text-lg font-semibold text-blue-800 dark:text-blue-200">
                Akses Admin/Manager
              </h3>
              <p class="text-blue-700 dark:text-blue-300">
                Anda memiliki akses ke fitur manajemen penuh.
              </p>
              <ul class="list-disc list-inside mt-2 text-blue-700 dark:text-blue-300">
                <li>
                  <NuxtLink to="/products" class="underline">Manajemen Produk</NuxtLink>
                </li>
                <li>
                  <NuxtLink to="/categories" class="underline"
                    >Manajemen Kategori</NuxtLink
                  >
                </li>
                <li>
                  <NuxtLink to="/customers" class="underline"
                    >Manajemen Pelanggan</NuxtLink
                  >
                </li>
                <li>
                  <NuxtLink to="/attendance" class="underline"
                    >Manajemen Absensi</NuxtLink
                  >
                </li>
              </ul>
            </div>

            <div
              v-else-if="userProfile?.role === 'cashier'"
              class="mt-6 p-4 bg-green-50 dark:bg-green-900 rounded-md"
            >
              <h3 class="text-lg font-semibold text-green-800 dark:text-green-200">
                Akses Kasir
              </h3>
              <p class="text-green-700 dark:text-green-300">
                Anda memiliki akses ke fitur transaksi dan absensi.
              </p>
              <ul class="list-disc list-inside mt-2 text-green-700 dark:text-green-300">
                <li>
                  <NuxtLink to="/cashier" class="underline">Halaman Kasir</NuxtLink>
                </li>
                <li>
                  <NuxtLink to="/attendance" class="underline">Absensi Saya</NuxtLink>
                </li>
                <li>
                  <NuxtLink to="/transactions" class="underline"
                    >Riwayat Transaksi</NuxtLink
                  >
                </li>
              </ul>
            </div>
          </section>

          <!-- Quick Actions Section -->
          <section class="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
            <h3 class="text-2xl font-semibold text-gray-900 dark:text-white mb-4">
              Aksi Cepat
            </h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <NuxtLink
                to="/cashier"
                class="flex items-center justify-center p-4 bg-blue-100 dark:bg-blue-800 rounded-md text-blue-800 dark:text-blue-100 hover:bg-blue-200 dark:hover:bg-blue-700 transition-colors"
              >
                <span class="font-medium">Buka Kasir</span>
              </NuxtLink>
              <NuxtLink
                to="/products"
                class="flex items-center justify-center p-4 bg-green-100 dark:bg-green-800 rounded-md text-green-800 dark:text-green-100 hover:bg-green-200 dark:hover:bg-green-700 transition-colors"
              >
                <span class="font-medium">Lihat Produk</span>
              </NuxtLink>
              <NuxtLink
                to="/transactions"
                class="flex items-center justify-center p-4 bg-purple-100 dark:bg-purple-800 rounded-md text-purple-800 dark:text-purple-100 hover:bg-purple-200 dark:hover:bg-purple-700 transition-colors"
              >
                <span class="font-medium">Riwayat Transaksi</span>
              </NuxtLink>
              <NuxtLink
                to="/attendance"
                class="flex items-center justify-center p-4 bg-orange-100 dark:bg-orange-800 rounded-md text-orange-800 dark:text-orange-100 hover:bg-orange-200 dark:hover:bg-orange-700 transition-colors"
              >
                <span class="font-medium">Absensi</span>
              </NuxtLink>
            </div>
          </section>
        </div>
      </div>

      <div v-else class="text-center bg-white dark:bg-gray-800 rounded-lg shadow-md p-8">
        <p class="text-gray-700 dark:text-gray-300 mb-4">
          Anda belum masuk. Silakan masuk untuk melanjutkan.
        </p>
        <Button @click="router.push('/login')">Masuk / Daftar</Button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  title: 'Dashboard - Aplikasi Kasir'
})
import { ref, onMounted } from "vue";
import { useRouter } from "vue-router";
import { useSupabaseClient, useSupabaseUser } from "#imports";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import type { User } from "@supabase/supabase-js";

interface UserProfile {
  id: string;
  email: string;
  full_name: string | null;
  role: "admin" | "manager" | "cashier";
  phone: string | null;
  address: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

const supabase = useSupabaseClient();
const user = useSupabaseUser();
const router = useRouter();

const userProfile = ref<UserProfile | null>(null);
const loadingLogout = ref(false);
const loadingUpdate = ref(false);
const newFullName = ref("");
const updateMessage = ref("");
const updateError = ref(false);

const fetchUserProfile = async (userId: string) => {
  const { data, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", userId)
    .single();

  if (error) {
    console.error("Error fetching user profile:", error.message);
    userProfile.value = null;
  } else {
    userProfile.value = data as UserProfile;
    newFullName.value = data.full_name || "";
  }
};

const handleLogout = async () => {
  loadingLogout.value = true;
  try {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
    router.push("/login");
  } catch (error: any) {
    console.error("Error logging out:", error.message);
    alert("Gagal keluar: " + error.message);
  } finally {
    loadingLogout.value = false;
  }
};

const updateProfile = async () => {
  loadingUpdate.value = true;
  updateMessage.value = "";
  updateError.value = false;

  if (!user.value) {
    updateMessage.value = "Anda harus login untuk memperbarui profil.";
    updateError.value = true;
    loadingUpdate.value = false;
    return;
  }

  try {
    const { data, error } = await supabase
      .from("profiles")
      .update({ full_name: newFullName.value, updated_at: new Date().toISOString() })
      .eq("id", user.value.id)
      .select()
      .single();

    if (error) throw error;

    userProfile.value = data as UserProfile;
    updateMessage.value = "Profil berhasil diperbarui!";
  } catch (error: any) {
    console.error("Error updating profile:", error.message);
    updateMessage.value = "Gagal memperbarui profil: " + error.message;
    updateError.value = true;
  } finally {
    loadingUpdate.value = false;
  }
};

onMounted(async () => {
  if (!user.value) {
    router.push("/login");
    return;
  }
  await fetchUserProfile(user.value.id);
});

// Watch for user changes (e.g., after login/logout)
watch(user, async (newUser) => {
  if (newUser) {
    await fetchUserProfile(newUser.id);
  } else {
    userProfile.value = null;
    router.push("/login");
  }
});
</script>

<style scoped>
/* No specific styles needed as @nuxt/ui and shadcn-nuxt handle styling */
</style>
