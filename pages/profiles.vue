<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-4">
    <h1 class="text-3xl font-bold mb-6 text-gray-900 dark:text-white">Profiles</h1>

    <div v-if="user" class="grid grid-cols-1 md:grid-cols-2 gap-8">
      <!-- Personal Data Section -->
      <Card>
        <CardHeader>
          <CardTitle>Personal Data</CardTitle>
        </CardHeader>
        <CardContent>
          <form @submit.prevent="updateProfile" class="space-y-4">
            <div>
              <Label for="email" class="mb-2">Email</Label>
              <Input
                id="email"
                :model-value="user.email"
                type="email"
                disabled
                class="bg-gray-100 dark:bg-gray-700 cursor-not-allowed"
              />
              <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
                Email cannot be changed here.
              </p>
            </div>
            <div>
              <Label for="fullName" class="mb-2">Full Name</Label>
              <Input id="fullName" v-model="userProfile.full_name" type="text" />
            </div>
            <div>
              <Label for="phone" class="mb-2">Phone</Label>
              <Input id="phone" v-model="userProfile.phone" type="text" />
            </div>
            <div>
              <Label for="address" class="mb-2">Address</Label>
              <Textarea id="address" v-model="userProfile.address" />
            </div>
            <div>
              <Label for="role" class="mb-2">Role</Label>
              <Input
                id="role"
                :model-value="userProfile.role"
                type="text"
                disabled
                class="bg-gray-100 dark:bg-gray-700 cursor-not-allowed"
              />
              <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
                Role can only be changed by an administrator.
              </p>
            </div>
            <div>
              <Label for="isActive" class="mb-2">Active Status</Label>
              <Input
                id="isActive"
                :model-value="userProfile.is_active ? 'Active' : 'Inactive'"
                type="text"
                disabled
                class="bg-gray-100 dark:bg-gray-700 cursor-not-allowed"
              />
            </div>
            <div>
              <Label for="createdAt" class="mb-2">Created At</Label>
              <Input
                id="createdAt"
                :model-value="formatDate(userProfile.created_at)"
                type="text"
                disabled
                class="bg-gray-100 dark:bg-gray-700 cursor-not-allowed"
              />
            </div>
            <div>
              <Label for="updatedAt" class="mb-2">Last Updated</Label>
              <Input
                id="updatedAt"
                :model-value="formatDate(userProfile.updated_at)"
                type="text"
                disabled
                class="bg-gray-100 dark:bg-gray-700 cursor-not-allowed"
              />
            </div>
            <Button type="submit" :disabled="loadingProfileUpdate">
              <span v-if="loadingProfileUpdate">Updating Profile...</span>
              <span v-else>Update Profile</span>
            </Button>
            <div
              v-if="profileUpdateMessage"
              :class="{
                'text-green-500': !profileUpdateError,
                'text-red-500': profileUpdateError,
              }"
              class="text-sm mt-2"
            >
              {{ profileUpdateMessage }}
            </div>
          </form>
        </CardContent>
      </Card>

      <!-- Account Settings Section -->
      <Card>
        <CardHeader>
          <CardTitle>Account Settings</CardTitle>
        </CardHeader>
        <CardContent>
          <form @submit.prevent="updatePassword" class="space-y-4">
            <div>
              <Label for="newPassword" class="mb-2">New Password</Label>
              <Input
                id="newPassword"
                v-model="passwordSettings.newPassword"
                type="password"
              />
            </div>
            <div>
              <Label for="confirmNewPassword" class="mb-2">Confirm New Password</Label>
              <Input
                id="confirmNewPassword"
                v-model="passwordSettings.confirmNewPassword"
                type="password"
              />
            </div>
            <Button type="submit" :disabled="loadingPasswordUpdate">
              <span v-if="loadingPasswordUpdate">Updating Password...</span>
              <span v-else>Update Password</span>
            </Button>
            <div
              v-if="passwordUpdateMessage"
              :class="{
                'text-green-500': !passwordUpdateError,
                'text-red-500': passwordUpdateError,
              }"
              class="text-sm mt-2"
            >
              {{ passwordUpdateMessage }}
            </div>
          </form>
          <Button
            @click="handleLogout"
            class="w-full mt-8"
            variant="destructive"
            :disabled="loadingLogout"
          >
            <span v-if="loadingLogout">Logging out...</span>
            <span v-else>Logout</span>
          </Button>
        </CardContent>
      </Card>
    </div>
    <div v-else class="text-center p-8 bg-white dark:bg-gray-800 rounded-lg shadow-md">
      <p class="text-gray-700 dark:text-gray-300 mb-4">
        You are not logged in. Please log in to view your profile.
      </p>
      <Button @click="router.push('/login')">Login / Register</Button>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  title: 'Profiles - Aplikasi Kasir'
})
import { ref, onMounted, watch } from "vue";
import { useRouter } from "vue-router";
import { useSupabaseClient, useSupabaseUser } from "#imports";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
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

const userProfile = ref<UserProfile>({
  id: "",
  email: "",
  full_name: null,
  role: "cashier",
  phone: null,
  address: null,
  is_active: true,
  created_at: "",
  updated_at: "",
});

const passwordSettings = ref({
  newPassword: "",
  confirmNewPassword: "",
});

const loadingProfileUpdate = ref(false);
const loadingPasswordUpdate = ref(false);
const loadingLogout = ref(false);
const profileUpdateMessage = ref("");
const profileUpdateError = ref(false);
const passwordUpdateMessage = ref("");
const passwordUpdateError = ref(false);

const fetchUserProfile = async (userId: string) => {
  const { data, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", userId)
    .single();

  if (error) {
    console.error("Error fetching user profile:", error.message);
    profileUpdateMessage.value = "Error fetching profile: " + error.message;
    profileUpdateError.value = true;
  } else {
    userProfile.value = data as UserProfile;
  }
};

const updateProfile = async () => {
  loadingProfileUpdate.value = true;
  profileUpdateMessage.value = "";
  profileUpdateError.value = false;

  if (!user.value) {
    profileUpdateMessage.value = "You must be logged in to update your profile.";
    profileUpdateError.value = true;
    loadingProfileUpdate.value = false;
    return;
  }

  try {
    const { data, error } = await supabase
      .from("profiles")
      .update({
        full_name: userProfile.value.full_name,
        phone: userProfile.value.phone,
        address: userProfile.value.address,
        updated_at: new Date().toISOString(),
      })
      .eq("id", user.value.id)
      .select()
      .single();

    if (error) throw error;

    userProfile.value = data as UserProfile;
    profileUpdateMessage.value = "Profile updated successfully!";
  } catch (error: any) {
    console.error("Error updating profile:", error.message);
    profileUpdateMessage.value = "Failed to update profile: " + error.message;
    profileUpdateError.value = true;
  } finally {
    loadingProfileUpdate.value = false;
  }
};

const updatePassword = async () => {
  loadingPasswordUpdate.value = true;
  passwordUpdateMessage.value = "";
  passwordUpdateError.value = false;

  if (passwordSettings.value.newPassword !== passwordSettings.value.confirmNewPassword) {
    passwordUpdateMessage.value = "New password and confirmation do not match.";
    passwordUpdateError.value = true;
    loadingPasswordUpdate.value = false;
    return;
  }

  if (!passwordSettings.value.newPassword) {
    passwordUpdateMessage.value = "Password cannot be empty.";
    passwordUpdateError.value = true;
    loadingPasswordUpdate.value = false;
    return;
  }

  try {
    const { error } = await supabase.auth.updateUser({
      password: passwordSettings.value.newPassword,
    });

    if (error) throw error;

    passwordUpdateMessage.value = "Password updated successfully!";
    passwordSettings.value.newPassword = "";
    passwordSettings.value.confirmNewPassword = "";
  } catch (error: any) {
    console.error("Error updating password:", error.message);
    passwordUpdateMessage.value = "Failed to update password: " + error.message;
    passwordUpdateError.value = true;
  } finally {
    loadingPasswordUpdate.value = false;
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
    alert("Failed to logout: " + error.message);
  } finally {
    loadingLogout.value = false;
  }
};

const formatDate = (dateString: string | null) => {
  if (!dateString) return "N/A";
  const options: Intl.DateTimeFormatOptions = {
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  };
  return new Date(dateString).toLocaleDateString(undefined, options);
};

onMounted(async () => {
  if (user.value) {
    await fetchUserProfile(user.value.id);
  } else {
    router.push("/login");
  }
});

watch(user, async (newUser) => {
  if (newUser) {
    await fetchUserProfile(newUser.id);
  } else {
    // Clear profile data if user logs out
    userProfile.value = {
      id: "",
      email: "",
      full_name: null,
      role: "cashier",
      phone: null,
      address: null,
      is_active: true,
      created_at: "",
      updated_at: "",
    };
    router.push("/login");
  }
});
</script>

<style scoped>
/* Add any specific styles for this page here if needed */
</style>
