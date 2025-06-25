<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-4">
    <h1 class="text-2xl sm:text-3xl font-bold mb-4 sm:mb-6 text-gray-900 dark:text-white">
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
          <DialogContent class="sm:max-w-[600px] p-6 max-h-[80vh] overflow-y-auto">
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
                <Checkbox id="shiftIsActive" v-model="shiftForm.is_active" />
                <Label for="shiftIsActive">Aktif</Label>
              </div>
              <DialogFooter class="flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2 pt-4">
                <DialogClose as-child>
                  <Button type="button" variant="outline" @click="cancelEdit"
                    class="w-full sm:w-auto mb-2 sm:mb-0"
                    >Batal</Button
                  >
                </DialogClose>
                <Button
                  v-if="isEditing"
                  type="button"
                  variant="destructive"
                  @click="confirmDeleteShift(shiftForm.id)"
                  :disabled="loading"
                  class="w-full sm:w-auto mb-2 sm:mb-0"
                >
                  Hapus Shift
                </Button>
                <Button type="submit" :disabled="loading" class="w-full sm:w-auto">
                  <span v-if="loading">Menyimpan...</span>
                  <span v-else>{{
                    isEditing ? "Perbarui Shift" : "Tambah Shift"
                  }}</span>
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <!-- Daftar Shift -->
      <Card>
        <CardHeader>
          <CardTitle>Daftar Shift</CardTitle>
        </CardHeader>
        <CardContent>
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
                <TableRow v-for="shift in shifts" :key="shift.id" @click="showShiftDetail(shift)" class="cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700">
                  <TableCell>{{ shift.name }}</TableCell>
                  <TableCell>{{ shift.start_time }}</TableCell>
                  <TableCell>{{ shift.end_time }}</TableCell>
                  <TableCell>
                    <Badge :variant="shift.is_active ? 'success' : 'destructive'">
                      {{ shift.is_active ? "Ya" : "Tidak" }}
                    </Badge>
                  </TableCell>
                  <TableCell>{{ formatDate(shift.created_at) }}</TableCell>
                  <TableCell>{{ formatDate(shift.updated_at) }}</TableCell>
                  <TableCell>
                    <DropdownMenu>
                      <DropdownMenuTrigger as-child>
                        <Button variant="ghost" class="h-8 w-8 p-0">
                          <span class="sr-only">Open menu</span>
                          <MoreHorizontal class="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuLabel>Aksi</DropdownMenuLabel>
                        <DropdownMenuItem @click="showShiftDetail(shift)">
                          <Info class="mr-2 h-4 w-4" />Detail
                        </DropdownMenuItem>
                        <DropdownMenuItem @click="editShift(shift)">
                          <Edit class="mr-2 h-4 w-4" />Edit
                        </DropdownMenuItem>
                        <DropdownMenuItem @click="confirmDeleteShift(shift.id)">
                          <Trash2 class="mr-2 h-4 w-4" />Hapus
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
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
        </CardContent>
      </Card>
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


    <!-- Shift Detail Dialog -->
    <Dialog :open="isShiftDetailOpen" @update:open="isShiftDetailOpen = $event">
      <DialogContent class="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Detail Shift</DialogTitle>
          <DialogDescription>Informasi lengkap mengenai shift ini.</DialogDescription>
        </DialogHeader>
        <div v-if="selectedShift" class="grid gap-4 py-4">
          <div class="grid grid-cols-4 items-center gap-4">
            <Label for="detailShiftName" class="text-right">Nama Shift</Label>
            <Input id="detailShiftName" :model-value="selectedShift.name" readonly class="col-span-3" />
          </div>
          <div class="grid grid-cols-4 items-center gap-4">
            <Label for="detailStartTime" class="text-right">Waktu Mulai</Label>
            <Input id="detailStartTime" :model-value="selectedShift.start_time" readonly class="col-span-3" />
          </div>
          <div class="grid grid-cols-4 items-center gap-4">
            <Label for="detailEndTime" class="text-right">Waktu Selesai</Label>
            <Input id="detailEndTime" :model-value="selectedShift.end_time" readonly class="col-span-3" />
          </div>
          <div class="grid grid-cols-4 items-center gap-4">
            <Label for="detailIsActive" class="text-right">Aktif</Label>
            <div class="col-span-3">
              <Badge :variant="selectedShift.is_active ? 'success' : 'destructive'">
                {{ selectedShift.is_active ? "Ya" : "Tidak" }}
              </Badge>
            </div>
          </div>
          <div class="grid grid-cols-4 items-center gap-4">
            <Label for="detailCreatedAt" class="text-right">Dibuat Pada</Label>
            <Input id="detailCreatedAt" :model-value="formatDate(selectedShift.created_at)" readonly class="col-span-3" />
          </div>
          <div class="grid grid-cols-4 items-center gap-4">
            <Label for="detailUpdatedAt" class="text-right">Diperbarui Pada</Label>
            <Input id="detailUpdatedAt" :model-value="formatDate(selectedShift.updated_at)" readonly class="col-span-3" />
          </div>
        </div>
        <DialogFooter>
          <DialogClose as-child>
            <Button type="button" variant="outline">Tutup</Button>
          </DialogClose>
          <Button @click="editShift(selectedShift!)">
            <Edit class="mr-2 h-4 w-4" />Edit Shift
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
    <Toaster />

</template>

<script setup lang="ts">
definePageMeta({
  title: 'Shifts - Aplikasi Kasir'
})
import { ref, onMounted, watch } from "vue";
import { useSupabaseClient, useSupabaseUser } from "#imports";
import { toast } from 'vue-sonner';
import { Toaster } from '@/components/ui/sonner';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea"; // Added for consistency with employee-shifts.vue
import { Checkbox } from "@/components/ui/checkbox";
import { Badge } from "@/components/ui/badge";
import 'vue-sonner/style.css';
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
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { MoreHorizontal, Edit, Trash2, Info } from "lucide-vue-next";

interface Shift {
  id: string;
  name: string;
  start_time: string;
  end_time: string;
  is_active: boolean;
  total_work_hours: number; // New field
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
const hasAdminOrManagerRole = ref(false);
const isShiftFormOpen = ref(false); // Controls the add/edit shift dialog
const isConfirmDeleteOpen = ref(false); // Controls the delete confirmation dialog
const shiftToDeleteId = ref<string | null>(null); // Stores the ID of the shift to be deleted
const isShiftDetailOpen = ref(false); // Controls the shift detail dialog
const selectedShift = ref<Shift | null>(null); // Stores the selected shift for detail view

const fetchShifts = async () => {
  loading.value = true;
  try {
    const { data, error } = await supabase
      .from("shifts")
      .select("*")
      .order("name", { ascending: true });

    if (error) throw error;
    shifts.value = data as Shift[];
  } catch (error: any) {
    toast.error("Gagal memuat shift!", {
      description: error.message,
    });
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
    toast.error("Gagal memeriksa peran pengguna!", {
      description: error.message,
    });
    hasAdminOrManagerRole.value = false;
    return;
  }
  if (!data) {
    toast.error("Data profil pengguna tidak ditemukan.");
    hasAdminOrManagerRole.value = false;
    return;
  }
  hasAdminOrManagerRole.value = data?.role === "admin" || data?.role === "manager";
  if (!hasAdminOrManagerRole.value) {
    toast.warning("Anda tidak memiliki izin untuk mengakses halaman ini.", {
      description: "Silakan hubungi administrator untuk mendapatkan akses.",
    });
  }
};

const saveShift = async () => {
  loading.value = true;
  try {
    if (isEditing.value) {
      const { error } = await supabase
        .from("shifts")
        .update({
          name: shiftForm.value.name,
          start_time: shiftForm.value.start_time,
          end_time: shiftForm.value.end_time,
          is_active: shiftForm.value.is_active,
          total_work_hours: calculateTotalWorkHours(shiftForm.value.start_time, shiftForm.value.end_time), // Calculate and save
          updated_at: new Date().toISOString(),
        })
        .eq("id", shiftForm.value.id);
      if (error) throw error;
      toast.success("Shift berhasil diperbarui!", {
        description: `Shift ${shiftForm.value.name} telah berhasil diperbarui.`,
      });
    } else {
      const { error } = await supabase.from("shifts").insert({
        name: shiftForm.value.name,
        start_time: shiftForm.value.start_time,
        end_time: shiftForm.value.end_time,
        is_active: shiftForm.value.is_active,
        total_work_hours: calculateTotalWorkHours(shiftForm.value.start_time, shiftForm.value.end_time), // Calculate and save
      });
      if (error) throw error;
      toast.success("Shift berhasil ditambahkan!", {
        description: `Shift ${shiftForm.value.name} telah berhasil ditambahkan.`,
      });
    }
    resetForm();
    await fetchShifts();
    isShiftFormOpen.value = false; // Close the dialog on success
  } catch (error: any) {
    toast.error("Gagal menyimpan shift!", {
      description: error.message,
    });
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
  isShiftFormOpen.value = true; // Open the dialog for editing
  isShiftDetailOpen.value = false; // Close detail dialog if open
};

const cancelEdit = () => {
  resetForm();
  isShiftFormOpen.value = false; // Close the dialog on cancel
};

const confirmDeleteShift = (id: string) => {
  shiftToDeleteId.value = id;
  isShiftFormOpen.value = false; // Close the shift form dialog
  isConfirmDeleteOpen.value = true;
};

const deleteShiftConfirmed = async () => {
  if (!shiftToDeleteId.value) return;

  loading.value = true;
  try {
    const { error } = await supabase
      .from("shifts")
      .delete()
      .eq("id", shiftToDeleteId.value);
    if (error) throw error;
    loading.value = false; // Set loading to false before closing dialog
    isConfirmDeleteOpen.value = false; // Close the confirmation dialog
    shiftToDeleteId.value = null; // Clear the ID
    toast.success("Shift berhasil dihapus!", {
      description: "Shift telah berhasil dihapus dari daftar.",
    });
    await fetchShifts();
  } catch (error: any) {
    toast.error("Gagal menghapus shift!", {
      description: error.message,
    });
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
    total_work_hours: 8, // Default value
  };
};

const calculateTotalWorkHours = (startTime: string, endTime: string): number => {
  const start = new Date(`2000-01-01T${startTime}`);
  const end = new Date(`2000-01-01T${endTime}`);
  let diffMs = end.getTime() - start.getTime();
  if (diffMs < 0) { // Handle overnight shifts
    diffMs += 24 * 60 * 60 * 1000;
  }
  return parseFloat((diffMs / (1000 * 60 * 60)).toFixed(2));
};

const showShiftDetail = (shift: Shift) => {
  selectedShift.value = shift;
  isShiftDetailOpen.value = true;
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
    toast.error("Terjadi kesalahan saat memuat data awal!", {
      description: error.message,
    });
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
