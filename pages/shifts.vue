<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-4">
    <h1 class="text-3xl font-bold mb-6 text-gray-900 dark:text-white">
      Manajemen Shift Kerja
    </h1>

    <div v-if="pageLoading" class="flex justify-center items-center h-64">
      <div class="spinner"></div>
    </div>

    <div
      v-else-if="!hasAdminOrManagerRole"
      class="text-center text-red-500 dark:text-red-400"
    >
      Anda tidak memiliki izin untuk mengakses halaman ini.
    </div>

    <div v-else>
      <div class="mb-6 flex justify-end">
        <Dialog :open="isShiftFormOpen" @update:open="isShiftFormOpen = $event">
          <DialogTrigger as-child>
            <Button @click="addNewShift">Tambah Shift Baru</Button>
          </DialogTrigger>
          <DialogContent class="sm:max-w-[600px] p-6">
            <DialogHeader>
              <DialogTitle>{{
                isEditing ? "Edit Shift" : "Tambah Shift Baru"
              }}</DialogTitle>
              <DialogDescription>
                {{
                  isEditing ? "Perbarui detail shift." : "Tambahkan shift baru ke daftar."
                }}
              </DialogDescription>
            </DialogHeader>
            <form @submit.prevent="saveShift" class="space-y-4 py-4">
              <div>
                <Label for="shiftName" class="mb-2">Nama Shift</Label>
                <Input
                  id="shiftName"
                  v-model="shiftForm.name"
                  type="text"
                  placeholder="Contoh: Shift Pagi"
                  required
                />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <Label for="startTime" class="mb-2">Waktu Mulai</Label>
                  <Input
                    id="startTime"
                    v-model="shiftForm.start_time"
                    type="time"
                    required
                  />
                </div>
                <div>
                  <Label for="endTime" class="mb-2">Waktu Selesai</Label>
                  <Input id="endTime" v-model="shiftForm.end_time" type="time" required />
                </div>
              </div>
              <div class="flex items-center space-x-2">
                <Checkbox id="shiftIsActive" v-model:checked="shiftForm.is_active" />
                <Label for="shiftIsActive">Aktif</Label>
              </div>
              <div v-if="errorMessage" class="text-red-500 text-sm mt-4">
                {{ errorMessage }}
              </div>
              <div v-if="successMessage" class="text-green-500 text-sm mt-4">
                {{ successMessage }}
              </div>
              <DialogFooter>
                <Button type="submit" :disabled="loading">
                  <span v-if="loading">Menyimpan...</span>
                  <span v-else>{{ isEditing ? "Perbarui Shift" : "Tambah Shift" }}</span>
                </Button>
                <DialogClose as-child>
                  <Button type="button" variant="outline" @click="cancelEdit"
                    >Batal</Button
                  >
                </DialogClose>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <!-- Daftar Shift -->
      <div class="bg-white dark:bg-gray-800 shadow-md rounded-lg p-6">
        <h2 class="text-2xl font-semibold mb-4 text-gray-900 dark:text-white">
          Daftar Shift
        </h2>
        <div class="overflow-x-auto">
          <Table class="min-w-full">
            <TableHeader>
              <TableRow>
                <TableHead class="min-w-[150px]">Nama Shift</TableHead>
                <TableHead class="min-w-[120px]">Waktu Mulai</TableHead>
                <TableHead class="min-w-[120px]">Waktu Selesai</TableHead>
                <TableHead class="min-w-[80px]">Aktif</TableHead>
                <TableHead class="min-w-[150px]">Dibuat Pada</TableHead>
                <TableHead class="min-w-[150px]">Diperbarui Pada</TableHead>
                <TableHead class="min-w-[150px]">Aksi</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              <TableRow v-for="shift in shifts" :key="shift.id">
                <TableCell>{{ shift.name }}</TableCell>
                <TableCell>{{ shift.start_time }}</TableCell>
                <TableCell>{{ shift.end_time }}</TableCell>
                <TableCell>{{ shift.is_active ? "Ya" : "Tidak" }}</TableCell>
                <TableCell>{{ formatDate(shift.created_at) }}</TableCell>
                <TableCell>{{ formatDate(shift.updated_at) }}</TableCell>
                <TableCell>
                  <Button
                    variant="outline"
                    size="sm"
                    @click="editShift(shift)"
                    class="mr-2"
                    >Edit</Button
                  >
                  <Button
                    variant="destructive"
                    size="sm"
                    @click="confirmDeleteShift(shift.id)"
                    :disabled="loading"
                    >Hapus</Button
                  >
                </TableCell>
              </TableRow>
            </TableBody>
          </Table>
        </div>
        <div
          v-if="shifts.length === 0 && !loading"
          class="text-center text-gray-500 dark:text-gray-400 mt-4"
        >
          Tidak ada shift ditemukan.
        </div>
      </div>

      <!-- Delete Confirmation Dialog -->
      <Dialog :open="isConfirmDeleteOpen" @update:open="isConfirmDeleteOpen = $event">
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Konfirmasi Hapus Shift</DialogTitle>
            <DialogDescription>
              Apakah Anda yakin ingin menghapus shift ini? Tindakan ini tidak dapat
              dibatalkan.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" @click="isConfirmDeleteOpen = false">Batal</Button>
            <Button
              variant="destructive"
              @click="deleteShiftConfirmed"
              :disabled="loading"
            >
              <span v-if="loading">Menghapus...</span>
              <span v-else>Hapus</span>
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  title: 'Shifts - Aplikasi Kasir'
})
import { ref, onMounted, watch } from "vue";
import { useSupabaseClient, useSupabaseUser } from "#imports";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogClose,
} from "@/components/ui/dialog";

interface Shift {
  id: string;
  name: string;
  start_time: string;
  end_time: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

const supabase = useSupabaseClient();
const user = useSupabaseUser();

const shifts = ref<Shift[]>([]);
const shiftForm = ref({
  id: "",
  name: "",
  start_time: "08:00:00",
  end_time: "16:00:00",
  is_active: true,
});

const pageLoading = ref(true); // Controls the overall page loading state
const isEditing = ref(false);
const loading = ref(false);
const errorMessage = ref("");
const successMessage = ref("");
const hasAdminOrManagerRole = ref(false);
const isShiftFormOpen = ref(false); // Controls the add/edit shift dialog
const isConfirmDeleteOpen = ref(false); // Controls the delete confirmation dialog
const shiftToDeleteId = ref<string | null>(null); // Stores the ID of the shift to be deleted

const fetchShifts = async () => {
  loading.value = true;
  errorMessage.value = "";
  try {
    const { data, error } = await supabase
      .from("shifts")
      .select("*")
      .order("name", { ascending: true });

    if (error) throw error;
    shifts.value = data as Shift[];
  } catch (error: any) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
};

const checkUserRole = async () => {
  if (!user.value) {
    hasAdminOrManagerRole.value = false;
    return;
  }
  const { data, error } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.value.id)
    .single();

  if (error) {
    console.error("Error fetching user role:", error.message);
    hasAdminOrManagerRole.value = false;
    return;
  }
  if (!data) {
    console.error("No profile data found for user.");
    hasAdminOrManagerRole.value = false;
    return;
  }
  hasAdminOrManagerRole.value = data?.role === "admin" || data?.role === "manager";
  if (!hasAdminOrManagerRole.value) {
    errorMessage.value = "Anda tidak memiliki izin untuk mengakses halaman ini.";
  }
};

const saveShift = async () => {
  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";
  try {
    if (isEditing.value) {
      const { error } = await supabase
        .from("shifts")
        .update({
          name: shiftForm.value.name,
          start_time: shiftForm.value.start_time,
          end_time: shiftForm.value.end_time,
          is_active: shiftForm.value.is_active,
          updated_at: new Date().toISOString(),
        })
        .eq("id", shiftForm.value.id);
      if (error) throw error;
      successMessage.value = "Shift berhasil diperbarui!";
    } else {
      const { error } = await supabase.from("shifts").insert({
        name: shiftForm.value.name,
        start_time: shiftForm.value.start_time,
        end_time: shiftForm.value.end_time,
        is_active: shiftForm.value.is_active,
      });
      if (error) throw error;
      successMessage.value = "Shift berhasil ditambahkan!";
    }
    resetForm();
    await fetchShifts();
    isShiftFormOpen.value = false; // Close the dialog on success
  } catch (error: any) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
};

const addNewShift = () => {
  resetForm();
  isShiftFormOpen.value = true;
};

const editShift = (shift: Shift) => {
  isEditing.value = true;
  shiftForm.value = { ...shift };
  errorMessage.value = "";
  successMessage.value = "";
  isShiftFormOpen.value = true; // Open the dialog for editing
};

const cancelEdit = () => {
  resetForm();
  isShiftFormOpen.value = false; // Close the dialog on cancel
};

const confirmDeleteShift = (id: string) => {
  shiftToDeleteId.value = id;
  isConfirmDeleteOpen.value = true;
};

const deleteShiftConfirmed = async () => {
  if (!shiftToDeleteId.value) return;

  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";
  try {
    const { error } = await supabase
      .from("shifts")
      .delete()
      .eq("id", shiftToDeleteId.value);
    if (error) throw error;
    successMessage.value = "Shift berhasil dihapus!";
    await fetchShifts();
    isConfirmDeleteOpen.value = false; // Close the confirmation dialog
    shiftToDeleteId.value = null; // Clear the ID
  } catch (error: any) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
};

const resetForm = () => {
  isEditing.value = false;
  shiftForm.value = {
    id: "",
    name: "",
    start_time: "08:00:00",
    end_time: "16:00:00",
    is_active: true,
  };
  shiftToDeleteId.value = null; // Clear the ID
};

const formatDate = (dateString: string) => {
  const options: Intl.DateTimeFormatOptions = {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  };
  return new Date(dateString).toLocaleDateString("id-ID", options);
};

onMounted(async () => {
  pageLoading.value = true; // Start loading state
  try {
    await checkUserRole();
    if (hasAdminOrManagerRole.value) {
      await fetchShifts();
    }
  } catch (error: any) {
    console.error("Error during initial setup:", error.message);
    errorMessage.value = "Terjadi kesalahan saat memuat data.";
  } finally {
    pageLoading.value = false; // End loading state
  }
});

watch(user, async (newUser) => {
  if (newUser) {
    await checkUserRole();
    if (hasAdminOrManagerRole.value) {
      await fetchShifts();
    }
  } else {
    hasAdminOrManagerRole.value = false;
    shifts.value = [];
  }
});
</script>
<style scoped>
.spinner {
  border: 4px solid rgba(0, 0, 0, 0.1);
  border-left-color: #3b82f6; /* Blue-500 */
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}
</style>
