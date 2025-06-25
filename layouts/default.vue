<template>
  <div class="flex flex-col h-screen bg-blue-50 dark:bg-gray-950 overflow-hidden">
    <!-- Top Bar -->
    <header
      class="flex items-center justify-between p-5.5 bg-white dark:bg-gray-950 border-b z-20"
    >
      <div class="flex items-center">
        <button
          @click="isSidebarOpen = !isSidebarOpen"
          :class="[
            'p-2 mr-4 text-gray-900 dark:text-white lg:hidden focus:outline-none rounded-md transition-all duration-200',
            isSidebarOpen
              ? 'bg-gray-200 dark:bg-gray-800 shadow-lg ring-2 ring-gray-400 dark:ring-gray-600 scale-110'
              : 'hover:bg-gray-100 dark:hover:bg-gray-800'
          ]"
          aria-label="Toggle sidebar"
        >
          <Icon
            name="lucide:menu"
            class="w-6 h-6 transition-transform duration-200"
            :style="{ transform: isSidebarOpen ? 'rotate(90deg)' : 'rotate(0deg)' }"
          />
        </button>
        <h2 class="text-xl font-bold text-gray-900 dark:text-white">
          Welcome, {{ userProfile?.full_name || "User" }}!
        </h2>
      </div>
      <div class="flex items-center space-x-3 md:space-x-4">
        <!-- Dark Mode Toggle -->
        <button
          @click="toggleDarkMode"
          class="pointer-auto"
          aria-label="Toggle dark mode"
        >
          <ClientOnly>
            <Icon
              :name="colorMode.preference === 'dark' ? 'lucide:moon' : 'lucide:sun'"
              class="w-8 h-8"
            />
            <template #fallback>
              <!-- Optional: Placeholder for server-side rendering if needed -->
              <Icon name="lucide:sun" class="w-8 h-8" />
            </template>
          </ClientOnly>
        </button>

        <NuxtLink to="/profiles">
          <img
            :src="
              userProfile?.full_name
                ? `https://api.dicebear.com/7.x/initials/svg?seed=${userProfile.full_name}`
                : 'https://api.dicebear.com/7.x/initials/svg?seed=User'
            "
            alt="User Avatar"
            class="w-8 h-8 md:w-9 md:h-9 rounded-full border-2 border-blue-500 dark:border-blue-400"
          />
        </NuxtLink>
      </div>
    </header>

    <div class="flex flex-1 overflow-hidden">
      <!-- Mobile Sidebar Overlay -->
      <div
        v-if="isSidebarOpen"
        class="fixed inset-0 opacity-50 bg-gray-900 z-30 lg:hidden"
        @click="isSidebarOpen = false"
      ></div>

      <!-- Sidebar -->
      <aside
        :class="isSidebarOpen ? 'translate-x-0' : '-translate-x-full'"
        class="fixed inset-y-0 left-0 h-screen w-64 max-w-xs bg-white dark:bg-gray-950 flex flex-col z-40 transition-transform duration-300 ease-in-out lg:translate-x-0 lg:static lg:w-70 lg:relative lg:flex-shrink-0"
      >
        <div class="flex flex-col h-full">
          <nav class="p-4 space-y-3 overflow-y-auto grow">
            <NuxtLink
              to="/"
              class="flex items-center p-3 text-gray-900 dark:text-white hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-all duration-200 ease-in-out transform hover:scale-105 hover:shadow-md"
              active-class="bg-gray-200 text-gray-900 dark:bg-gray-800 dark:text-white hover:text-gray-900 dark:hover:text-white hover:bg-gray-200 dark:hover:bg-gray-800 scale-100 shadow-lg"
            >
              <Icon name="lucide:home" class="w-5 h-5 mr-3" />
              Dashboard
            </NuxtLink>
            <NuxtLink
              v-if="userProfile?.role === 'admin' || userProfile?.role === 'manager'"
              to="/products"
              class="flex items-center p-3 text-gray-900 dark:text-white hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-all duration-200 ease-in-out transform hover:scale-105 hover:shadow-md"
              active-class="bg-gray-200 text-gray-900 dark:bg-gray-800 dark:text-white hover:text-gray-900 dark:hover:text-white hover:bg-gray-200 dark:hover:bg-gray-800 scale-100 shadow-lg"
            >
              <Icon name="lucide:package" class="w-5 h-5 mr-3" />
              Products
            </NuxtLink>
            <NuxtLink
              v-if="userProfile?.role === 'admin' || userProfile?.role === 'manager'"
              to="/categories"
              class="flex items-center p-3 text-gray-900 dark:text-white hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-all duration-200 ease-in-out transform hover:scale-105 hover:shadow-md"
              active-class="bg-gray-200 text-gray-900 dark:bg-gray-800 dark:text-white hover:text-gray-900 dark:hover:text-white hover:bg-gray-200 dark:hover:bg-gray-800 scale-100 shadow-lg"
            >
              <Icon name="lucide:tag" class="w-5 h-5 mr-3" />
              Categories
            </NuxtLink>
            <NuxtLink
              v-if="userProfile?.role === 'admin' || userProfile?.role === 'manager'"
              to="/customers"
              class="flex items-center p-3 text-gray-900 dark:text-white hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-all duration-200 ease-in-out transform hover:scale-105 hover:shadow-md"
              active-class="bg-gray-200 text-gray-900 dark:bg-gray-800 dark:text-white hover:text-gray-900 dark:hover:text-white hover:bg-gray-200 dark:hover:bg-gray-800 scale-100 shadow-lg"
            >
              <Icon name="lucide:users" class="w-5 h-5 mr-3" />
              Customers
            </NuxtLink>
            <NuxtLink
              v-if="userProfile?.role === 'admin' || userProfile?.role === 'manager' || userProfile?.role === 'cashier'"
              to="/transactions"
              class="flex items-center p-3 text-gray-900 dark:text-white hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-all duration-200 ease-in-out transform hover:scale-105 hover:shadow-md"
              active-class="bg-gray-200 text-gray-900 dark:bg-gray-800 dark:text-white hover:text-gray-900 dark:hover:text-white hover:bg-gray-200 dark:hover:bg-gray-800 scale-100 shadow-lg"
            >
              <Icon name="lucide:receipt" class="w-5 h-5 mr-3" />
              Transactions
            </NuxtLink>
            <NuxtLink
              v-if="userProfile?.role === 'admin' || userProfile?.role === 'manager' || userProfile?.role === 'cashier'"
              to="/cashier"
              class="flex items-center p-3 text-gray-900 dark:text-white hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-all duration-200 ease-in-out transform hover:scale-105 hover:shadow-md"
              active-class="bg-gray-200 text-gray-900 dark:bg-gray-800 dark:text-white hover:text-gray-900 dark:hover:text-white hover:bg-gray-200 dark:hover:bg-gray-800 scale-100 shadow-lg"
            >
              <Icon name="lucide:shopping-cart" class="w-5 h-5 mr-3" />
              Cashier
            </NuxtLink>
            <NuxtLink
              v-if="userProfile?.role === 'admin' || userProfile?.role === 'manager'"
              to="/employee-shifts"
              class="flex items-center p-3 text-gray-900 dark:text-white hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-all duration-200 ease-in-out transform hover:scale-105 hover:shadow-md"
              active-class="bg-gray-200 text-gray-900 dark:bg-gray-800 dark:text-white hover:text-gray-900 dark:hover:text-white hover:bg-gray-200 dark:hover:bg-gray-800 scale-100 shadow-lg"
            >
              <Icon name="lucide:briefcase" class="w-5 h-5 mr-3" />
              Employee Shifts
            </NuxtLink>
            <NuxtLink
              v-if="userProfile?.role === 'admin' || userProfile?.role === 'manager'"
              to="/shifts"
              class="flex items-center p-3 text-gray-900 dark:text-white hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-all duration-200 ease-in-out transform hover:scale-105 hover:shadow-md"
              active-class="bg-gray-200 text-gray-900 dark:bg-gray-800 dark:text-white hover:text-gray-900 dark:hover:text-white hover:bg-gray-200 dark:hover:bg-gray-800 scale-100 shadow-lg"
            >
              <Icon name="lucide:clock" class="w-5 h-5 mr-3" />
              Shifts
            </NuxtLink>
            <NuxtLink
              to="/attendance"
              class="flex items-center p-3 text-gray-900 dark:text-white hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-all duration-200 ease-in-out transform hover:scale-105 hover:shadow-md"
              active-class="bg-gray-200 text-gray-900 dark:bg-gray-800 dark:text-white hover:text-gray-900 dark:hover:text-white hover:bg-gray-200 dark:hover:bg-gray-800 scale-100 shadow-lg"
            >
              <Icon name="lucide:calendar-check" class="w-5 h-5 mr-3" />
              Attendance
            </NuxtLink>
            <div
              v-if="userProfile?.role === 'admin' || userProfile?.role === 'manager'"
              class="flex flex-col gap-2 pt-4 mt-4 border-t border-gray-200 dark:border-gray-700"
            >
              <h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">
                Reports
              </h2>
              <NuxtLink
                to="/reports/sales"
                class="flex items-center p-3 text-gray-900 dark:text-white hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-all duration-200 ease-in-out transform hover:scale-105 hover:shadow-md"
                active-class="bg-gray-200 text-gray-900 dark:bg-gray-800 dark:text-white hover:text-gray-900 dark:hover:text-white hover:bg-gray-200 dark:hover:bg-gray-800 scale-100 shadow-lg"
              >
                <Icon name="lucide:bar-chart-2" class="w-5 h-5 mr-3" />
                Sales Report
              </NuxtLink>
              <NuxtLink
                to="/reports/products"
                class="flex items-center p-3 text-gray-900 dark:text-white hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-all duration-200 ease-in-out transform hover:scale-105 hover:shadow-md"
                active-class="bg-gray-200 text-gray-900 dark:bg-gray-800 dark:text-white hover:text-gray-900 dark:hover:text-white hover:bg-gray-200 dark:hover:bg-gray-800 scale-100 shadow-lg"
              >
                <Icon name="lucide:box" class="w-5 h-5 mr-3" />
                Product Report
              </NuxtLink>
              <NuxtLink
                to="/reports/attendance"
                class="flex items-center p-3 text-gray-900 dark:text-white hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-all duration-200 ease-in-out transform hover:scale-105 hover:shadow-md"
                active-class="bg-gray-200 text-gray-900 dark:bg-gray-800 dark:text-white hover:text-gray-900 dark:hover:text-white hover:bg-gray-200 dark:hover:bg-gray-800 scale-100 shadow-lg"
              >
                <Icon name="lucide:clipboard-check" class="w-5 h-5 mr-3" />
                Attendance Report
              </NuxtLink>
            </div>
            <!-- Admin Links -->
            <div
              v-if="userProfile?.role === 'admin'"
              class="pt-4 mt-4 border-t border-gray-200 dark:border-gray-700"
            >
              <h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Admin</h2>
              <NuxtLink
                to="/admin/employees"
                class="flex items-center p-3 text-gray-900 dark:text-white hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-all duration-200 ease-in-out transform hover:scale-105 hover:shadow-md"
                active-class="bg-gray-200 text-gray-900 dark:bg-gray-800 dark:text-white hover:text-gray-900 dark:hover:text-white hover:bg-gray-200 dark:hover:bg-gray-800 scale-100 shadow-lg"
              >
                <Icon name="lucide:users-round" class="w-5 h-5 mr-3" />
                Employee Management
              </NuxtLink>
            </div>
          </nav>
          <div class="p-4 border-t border-gray-200 dark:border-gray-700 mt-4 mb-4 lg:mb-20">
            <Dialog>
              <DialogTrigger as-child>
                <Button
                  variant="destructive"
                  class="w-full flex items-center justify-center p-3 rounded-lg transition-colors duration-200 font-medium"
                >
                  <Icon name="lucide:log-out" class="w-5 h-5 mr-3" />
                  Logout
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Confirm Logout</DialogTitle>
                  <DialogDescription>
                    Are you sure you want to log out? You will be redirected to the login
                    page.
                  </DialogDescription>
                </DialogHeader>
                <DialogFooter>
                  <DialogClose as-child>
                    <Button variant="outline"> Cancel </Button>
                  </DialogClose>
                  <Button variant="destructive" @click="logout"> Logout </Button>
                </DialogFooter>
              </DialogContent>
            </Dialog>
          </div>
        </div>
      </aside>

      <!-- Main Content -->
      <main class="flex-1 flex flex-col overflow-hidden">
        <!-- Page Content -->
        <div class="flex-1 overflow-y-auto p-8 bg-gray-100 dark:bg-gray-900">
          <slot />
        </div>
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch, computed } from "vue";
import { useSupabaseClient, useSupabaseUser, useColorMode } from "#imports";
import { useRouter } from "vue-router";
import {
  HomeIcon,
  BellIcon,
  SettingsIcon,
  LogOutIcon,
  UsersRoundIcon,
  MenuIcon,
  SunIcon,
  MoonIcon,
} from "lucide-vue-next";

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
const colorMode = useColorMode();

const isSidebarOpen = ref(false);
const userProfile = ref<UserProfile | null>(null);

const toggleDarkMode = () => {
  colorMode.preference = colorMode.preference === "dark" ? "light" : "dark";
};

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
  }
};

const logout = async () => {
  await supabase.auth.signOut();
  router.push("/login");
};

onMounted(async () => {
  if (user.value) {
    await fetchUserProfile(user.value.id);
  }
});

watch(user, async (newUser) => {
  if (newUser) {
    await fetchUserProfile(newUser.id);
  } else {
    userProfile.value = null;
  }
});
</script>
