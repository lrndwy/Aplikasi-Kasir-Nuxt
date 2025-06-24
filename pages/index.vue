<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-2 sm:p-4">
    <div class="w-full space-y-8">
    <h1 class="text-2xl sm:text-3xl font-bold mb-4 sm:mb-6 text-gray-900 dark:text-white">
      Dashboard - Aplikasi Kasir
    </h1>

      <div v-if="user" class="space-y-8">
        <!-- Overview Section -->
        <Card>
          <CardHeader>
            <CardTitle>Overview</CardTitle>
          </CardHeader>
          <CardContent>
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
              <!-- Card 1: Total Penjualan Hari Ini -->
              <Card>
                <CardContent class="p-4">
                  <div class="flex items-center gap-2 mb-2">
                    <DollarSignIcon class="h-5 w-5 text-gray-500 dark:text-gray-400" />
                    <p class="text-sm text-gray-500 dark:text-gray-400">
                      Total Penjualan Hari Ini
                    </p>
                  </div>
                  <p class="text-2xl font-bold text-gray-900 dark:text-white">Rp 0</p>
                </CardContent>
              </Card>
              <!-- Card 2: Jumlah Transaksi -->
              <Card>
                <CardContent class="p-4">
                  <div class="flex items-center gap-2 mb-2">
                    <ReceiptTextIcon class="h-5 w-5 text-gray-500 dark:text-gray-400" />
                    <p class="text-sm text-gray-500 dark:text-gray-400">Jumlah Transaksi</p>
                  </div>
                  <p class="text-2xl font-bold text-gray-900 dark:text-white">0</p>
                </CardContent>
              </Card>
              <!-- Card 3: Produk Terjual -->
              <Card>
                <CardContent class="p-4">
                  <div class="flex items-center gap-2 mb-2">
                    <PackageIcon class="h-5 w-5 text-gray-500 dark:text-gray-400" />
                    <p class="text-sm text-gray-500 dark:text-gray-400">Produk Terjual</p>
                  </div>
                  <p class="text-2xl font-bold text-gray-900 dark:text-white">0</p>
                </CardContent>
              </Card>
              <!-- Card 4: Pengguna Aktif -->
              <Card>
                <CardContent class="p-4">
                  <div class="flex items-center gap-2 mb-2">
                    <UsersIcon class="h-5 w-5 text-gray-500 dark:text-gray-400" />
                    <p class="text-sm text-gray-500 dark:text-gray-400">Pengguna Aktif</p>
                  </div>
                  <p class="text-2xl font-bold text-gray-900 dark:text-white">1</p>
                </CardContent>
              </Card>
            </div>
          </CardContent>
        </Card>

        <!-- Attendance Status Section -->
        <Card>
          <CardHeader>
            <CardTitle>Status Absensi Hari Ini</CardTitle>
          </CardHeader>
          <CardContent>
            <div v-if="loadingAttendance" class="flex justify-center items-center h-24">
              <p class="text-gray-500 dark:text-gray-400">Memuat status absensi...</p>
            </div>
            <div v-else-if="todayAttendance" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
              <Card>
                <CardHeader class="pb-2">
                  <CardTitle class="text-xl font-medium text-gray-500 dark:text-gray-400">
                    Status Hari Ini
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div class="flex items-center gap-2">
                    <Badge :variant="getStatusVariant(todayAttendance.status)">
                      {{ todayAttendance.status || 'Belum Absen' }}
                    </Badge>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader class="pb-2">
                  <CardTitle class="text-xl font-medium text-gray-500 dark:text-gray-400">
                    Check-in
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div class="flex items-center gap-2">
                    <ClockIcon class="h-4 w-4 text-gray-500 dark:text-gray-400" />
                    <span class="text-xl font-semibold">
                      {{ todayAttendance.check_in ? formatTime(todayAttendance.check_in) : '-' }}
                    </span>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader class="pb-2">
                  <CardTitle class="text-xl font-medium text-gray-500 dark:text-gray-400">
                    Check-out
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div class="flex items-center gap-2">
                    <ClockIcon class="h-4 w-4 text-gray-500 dark:text-gray-400" />
                    <span class="text-xl font-semibold">
                      {{ todayAttendance.check_out ? formatTime(todayAttendance.check_out) : '-' }}
                    </span>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader class="pb-2">
                  <CardTitle class="text-xl font-medium text-gray-500 dark:text-gray-400">
                    Total Jam Kerja
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div class="flex items-center gap-2">
                    <ClockIcon class="h-4 w-4 text-gray-500 dark:text-gray-400" />
                    <span class="text-xl font-semibold">
                      {{ todayAttendance.total_hours ? `${todayAttendance.total_hours} jam` : '-' }}
                    </span>
                  </div>
                </CardContent>
              </Card>
            </div>
            <div v-else class="text-center p-4">
              <p class="text-gray-700 dark:text-gray-300">Belum ada catatan absensi untuk hari ini.</p>
              <NuxtLink to="/attendance" class="text-blue-500 hover:underline mt-2 block">
                Lakukan Absensi Sekarang
              </NuxtLink>
            </div>
          </CardContent>
        </Card>

        <!-- User Profile and Role Access Section -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4 sm:gap-8">
          <Card>
            <CardHeader>
              <CardTitle>Informasi Profil Anda:</CardTitle>
            </CardHeader>
            <CardContent class="space-y-4">
              <div class="flex items-center gap-3">
                <MailIcon class="h-5 w-5 text-gray-500 dark:text-gray-400" />
                <p class="text-gray-700 dark:text-gray-300">
                  <strong class="font-semibold">Email:</strong> {{ user.email }}
                </p>
              </div>
              <div class="flex items-center gap-3">
                <UserCircleIcon class="h-5 w-5 text-gray-500 dark:text-gray-400" />
                <p class="text-gray-700 dark:text-gray-300">
                  <strong class="font-semibold">Nama Lengkap:</strong>
                  {{ userProfile?.full_name || "Belum diatur" }}
                </p>
              </div>
              <div class="flex items-center gap-3">
                <BriefcaseIcon class="h-5 w-5 text-gray-500 dark:text-gray-400" />
                <p class="text-gray-700 dark:text-gray-300">
                  <strong class="font-semibold">Peran: </strong>
                  <span class="capitalize">{{ userProfile?.role || "Tidak Diketahui" }}</span>
                </p>
              </div>

              <div
                v-if="userProfile?.role === 'admin' || userProfile?.role === 'manager'"
                class="mt-6 p-4 bg-blue-50 dark:bg-blue-900/30 rounded-lg border border-blue-200 dark:border-blue-700"
              >
                <h3 class="text-lg font-semibold text-blue-800 dark:text-blue-200 mb-3">
                  <span class="flex items-center gap-2">
                    <BriefcaseIcon class="h-5 w-5" /> Akses Admin/Manager
                  </span>
                </h3>
                <p class="text-blue-700 dark:text-blue-300 mb-3">
                  Anda memiliki akses ke fitur manajemen penuh:
                </p>
                <ul class="space-y-2 text-blue-700 dark:text-blue-300">
                  <li>
                    <NuxtLink to="/products" class="flex items-center gap-2 hover:underline">
                      <PackageIcon class="h-4 w-4" /> Manajemen Produk
                    </NuxtLink>
                  </li>
                  <li>
                    <NuxtLink to="/categories" class="flex items-center gap-2 hover:underline">
                      <LayoutGridIcon class="h-4 w-4" /> Manajemen Kategori
                    </NuxtLink>
                  </li>
                  <li>
                    <NuxtLink to="/customers" class="flex items-center gap-2 hover:underline">
                      <UsersIcon class="h-4 w-4" /> Manajemen Pelanggan
                    </NuxtLink>
                  </li>
                  <li>
                    <NuxtLink to="/attendance" class="flex items-center gap-2 hover:underline">
                      <CalendarDaysIcon class="h-4 w-4" /> Manajemen Absensi
                    </NuxtLink>
                  </li>
                </ul>
              </div>

              <div
                v-else-if="userProfile?.role === 'cashier'"
                class="mt-6 p-4 bg-green-50 dark:bg-green-900/30 rounded-lg border border-green-200 dark:border-green-700"
              >
                <h3 class="text-lg font-semibold text-green-800 dark:text-green-200 mb-3">
                  <span class="flex items-center gap-2">
                    <BriefcaseIcon class="h-5 w-5" /> Akses Kasir
                  </span>
                </h3>
                <p class="text-green-700 dark:text-green-300 mb-3">
                  Anda memiliki akses ke fitur transaksi dan absensi:
                </p>
                <ul class="space-y-2 text-green-700 dark:text-green-300">
                  <li>
                    <NuxtLink to="/cashier" class="flex items-center gap-2 hover:underline">
                      <ShoppingCartIcon class="h-4 w-4" /> Halaman Kasir
                    </NuxtLink>
                  </li>
                  <li>
                    <NuxtLink to="/attendance" class="flex items-center gap-2 hover:underline">
                      <CalendarDaysIcon class="h-4 w-4" /> Absensi Saya
                    </NuxtLink>
                  </li>
                  <li>
                    <NuxtLink to="/transactions" class="flex items-center gap-2 hover:underline">
                      <HistoryIcon class="h-4 w-4" /> Riwayat Transaksi
                    </NuxtLink>
                  </li>
                </ul>
              </div>
            </CardContent>
          </Card>

          <!-- Quick Actions Section -->
          <Card>
            <CardHeader>
              <CardTitle>Aksi Cepat</CardTitle>
            </CardHeader>
            <CardContent>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <NuxtLink
                  to="/cashier"
                  class="flex flex-col items-center justify-center p-4 bg-blue-100 dark:bg-blue-800 rounded-lg text-blue-800 dark:text-blue-100 hover:bg-blue-200 dark:hover:bg-blue-700 transition-colors shadow-sm"
                >
                  <ShoppingCartIcon class="h-8 w-8 mb-2" />
                  <span class="font-semibold text-center">Buka Kasir</span>
                </NuxtLink>
                <NuxtLink
                  to="/products"
                  class="flex flex-col items-center justify-center p-4 bg-green-100 dark:bg-green-800 rounded-lg text-green-800 dark:text-green-100 hover:bg-green-200 dark:hover:bg-green-700 transition-colors shadow-sm"
                >
                  <PackageIcon class="h-8 w-8 mb-2" />
                  <span class="font-semibold text-center">Lihat Produk</span>
                </NuxtLink>
                <NuxtLink
                  to="/transactions"
                  class="flex flex-col items-center justify-center p-4 bg-purple-100 dark:bg-purple-800 rounded-lg text-purple-800 dark:text-purple-100 hover:bg-purple-200 dark:hover:bg-purple-700 transition-colors shadow-sm"
                >
                  <HistoryIcon class="h-8 w-8 mb-2" />
                  <span class="font-semibold text-center">Riwayat Transaksi</span>
                </NuxtLink>
                <NuxtLink
                  to="/attendance"
                  class="flex flex-col items-center justify-center p-4 bg-orange-100 dark:bg-orange-800 rounded-lg text-orange-800 dark:text-orange-100 hover:bg-orange-200 dark:hover:bg-orange-700 transition-colors shadow-sm"
                >
                  <CalendarDaysIcon class="h-8 w-8 mb-2" />
                  <span class="font-semibold text-center">Absensi</span>
                </NuxtLink>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      <Card v-else class="text-center p-4 sm:p-8">
        <CardContent>
          <p class="text-gray-700 dark:text-gray-300 mb-4">
            Anda belum masuk. Silakan masuk untuk melanjutkan.
          </p>
          <Button @click="router.push('/login')">Masuk / Daftar</Button>
        </CardContent>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  title: 'Dashboard - Aplikasi Kasir'
})
import { ref, onMounted, watch } from "vue";
import { useRouter } from "vue-router";
import { useSupabaseClient, useSupabaseUser } from "#imports";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { DollarSignIcon, ReceiptTextIcon, PackageIcon, UsersIcon, MailIcon, UserCircleIcon, BriefcaseIcon, ShoppingCartIcon, LayoutGridIcon, HistoryIcon, CalendarDaysIcon, ClockIcon } from 'lucide-vue-next';
import { Badge } from "@/components/ui/badge";
import { toast } from 'vue-sonner';
import { Toaster } from '@/components/ui/sonner';
import 'vue-sonner/style.css';
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

interface Attendance {
  id: string;
  employee_id: string;
  date: string;
  check_in: string | null;
  check_out: string | null;
  check_in_photo_url: string | null;
  check_out_photo_url: string | null;
  total_hours: number | null;
  status: "present" | "absent" | "late" | "half_day" | "sick" | "permission" | "leave" | "remote";
  notes: string | null;
  created_at: string;
  updated_at: string;
}

const todayAttendance = ref<Attendance | null>(null);
const loadingAttendance = ref(false);

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

const fetchTodayAttendance = async () => {
  if (!user.value) return;
  loadingAttendance.value = true;
  try {
    const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
    const { data, error } = await supabase
      .from("attendance")
      .select("*")
      .eq("employee_id", user.value.id)
      .eq("date", today)
      .single();

    if (error && error.code !== "PGRST116") {
      // PGRST116 means no rows found
      throw error;
    }
    todayAttendance.value = data as Attendance;
  } catch (error: any) {
    toast.error("Gagal memuat absensi hari ini", {
      description: error.message,
    });
  } finally {
    loadingAttendance.value = false;
  }
};

const formatTime = (dateTimeString: string) => {
  const options: Intl.DateTimeFormatOptions = {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  };
  return new Date(dateTimeString).toLocaleTimeString("id-ID", options);
};

const getStatusVariant = (
  status: "present" | "absent" | "late" | "half_day" | "sick" | "permission" | "leave" | "remote"
) => {
  switch (status) {
    case "present":
      return "default";
    case "late":
      return "secondary";
    case "absent":
      return "destructive";
    case "sick":
      return "outline";
    case "permission":
      return "outline";
    case "half_day":
      return "outline";
    case "leave":
      return "info";
    case "remote":
      return "success";
    default:
      return "default";
  }
};

onMounted(async () => {
  if (!user.value) {
    router.push("/login");
    return;
  }
  await fetchUserProfile(user.value.id);
  await fetchTodayAttendance(); // Fetch attendance on mount
});

// Watch for user changes (e.g., after login/logout)
watch(user, async (newUser) => {
  if (newUser) {
    await fetchUserProfile(newUser.id);
    await fetchTodayAttendance(); // Fetch attendance when user changes
  } else {
    userProfile.value = null;
    todayAttendance.value = null; // Clear attendance data on logout
    router.push("/login");
  }
});

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
