<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-2 sm:p-4">
    <h1 class="text-2xl sm:text-3xl font-bold mb-4 sm:mb-6 text-gray-900 dark:text-white">
      Manajemen Jadwal Shift Karyawan
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
        <Dialog
          :open="isEmployeeShiftFormOpen"
          @update:open="isEmployeeShiftFormOpen = $event"
        >
          <DialogTrigger as-child>
            <Button @click="addNewEmployeeShift">Tetapkan Jadwal Shift Baru</Button>
          </DialogTrigger>
          <DialogContent class="sm:max-w-[600px] p-6 max-h-[80vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>{{
                isEditing ? "Edit Jadwal Shift" : "Tetapkan Jadwal Shift Baru"
              }}</DialogTitle>
              <DialogDescription>
                {{
                  isEditing
                    ? "Perbarui detail jadwal shift karyawan."
                    : "Tetapkan jadwal shift baru untuk karyawan."
                }}
              </DialogDescription>
            </DialogHeader>
            <form @submit.prevent="saveEmployeeShift" class="space-y-4 py-4">
              <div>
                <Label for="employeeSelect">Karyawan</Label>
                <Select v-model="employeeShiftForm.employee_id" :disabled="isEditing">
                  <SelectTrigger id="employeeSelect" class="w-full mt-2">
                    <SelectValue
                      :placeholder="
                        employeeShiftForm.employee_id
                          ? employees.find((e) => e.id === employeeShiftForm.employee_id)
                              ?.full_name
                          : 'Pilih Karyawan'
                      "
                    />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem
                      v-for="employee in employees"
                      :key="employee.id"
                      :value="employee.id"
                    >
                      {{ employee.full_name }}
                    </SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label for="shiftSelect">Shift</Label>
                <Select v-model="employeeShiftForm.shift_id">
                  <SelectTrigger id="shiftSelect" class="w-full mt-2">
                    <SelectValue
                      :placeholder="
                        employeeShiftForm.shift_id
                          ? shifts.find((s) => s.id === employeeShiftForm.shift_id)?.name
                          : 'Pilih Shift'
                      "
                    />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem
                      v-for="shift in activeShifts"
                      :key="shift.id"
                      :value="shift.id"
                    >
                      {{ shift.name }} ({{ shift.start_time }} - {{ shift.end_time }})
                    </SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label for="dayOfWeek">Hari dalam Seminggu</Label>
                <Select
                  v-model.number="employeeShiftForm.day_of_week"
                  :disabled="isEditing"
                >
                  <SelectTrigger id="dayOfWeek" class="w-full mt-2">
                    <SelectValue
                      :placeholder="getDayName(employeeShiftForm.day_of_week)"
                    />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem :value="0">Minggu</SelectItem>
                    <SelectItem :value="1">Senin</SelectItem>
                    <SelectItem :value="2">Selasa</SelectItem>
                    <SelectItem :value="3">Rabu</SelectItem>
                    <SelectItem :value="4">Kamis</SelectItem>
                    <SelectItem :value="5">Jumat</SelectItem>
                    <SelectItem :value="6">Sabtu</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div class="flex items-center space-x-2">
                <Checkbox
                  id="employeeShiftIsActive"
                  v-model="employeeShiftForm.is_active"
                />
                <Label for="employeeShiftIsActive">Aktif</Label>
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
                  @click="confirmDeleteEmployeeShift(employeeShiftForm.id)"
                  :disabled="loading"
                  class="w-full sm:w-auto mb-2 sm:mb-0"
                >
                  Hapus Jadwal Shift
                </Button>
                <Button type="submit" :disabled="loading" class="w-full sm:w-auto">
                  <span v-if="loading">Menyimpan...</span>
                  <span v-else>{{
                    isEditing ? "Perbarui Jadwal" : "Tetapkan Jadwal"
                  }}</span>
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <!-- Daftar Jadwal Shift Karyawan -->
      <Card>
        <CardHeader>
          <CardTitle>Daftar Jadwal Shift</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead class="min-w-[150px]">Karyawan</TableHead>
                <TableHead class="min-w-[150px]">Shift</TableHead>
                <TableHead class="min-w-[80px]">Hari</TableHead>
                <TableHead class="min-w-[80px]">Aktif</TableHead>
                <TableHead class="min-w-[150px] hidden md:table-cell">Dibuat Pada</TableHead>
                <TableHead class="min-w-[150px]">Aksi</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              <TableRow v-for="employeeShift in employeeShifts" :key="employeeShift.id" @click="showEmployeeShiftDetail(employeeShift)" class="cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700">
                <TableCell>{{ employeeShift.employee_name }}</TableCell>
                <TableCell
                  >{{ employeeShift.shift_name }} ({{ employeeShift.shift_start_time }} -
                  {{ employeeShift.shift_end_time }})</TableCell
                >
                <TableCell>{{ getDayName(employeeShift.day_of_week) }}</TableCell>
                <TableCell>
                  <Badge :variant="employeeShift.is_active ? 'success' : 'destructive'">
                    {{ employeeShift.is_active ? "Ya" : "Tidak" }}
                  </Badge>
                </TableCell>
                <TableCell class="hidden md:table-cell">{{ formatDate(employeeShift.created_at) }}</TableCell>
                <TableCell @click.stop>
                  <DropdownMenu>
                    <DropdownMenuTrigger as-child>
                      <Button variant="ghost" class="h-8 w-8 p-0">
                        <span class="sr-only">Open menu</span>
                        <MoreHorizontal class="h-4 w-4" />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      <DropdownMenuLabel>Aksi</DropdownMenuLabel>
                      <DropdownMenuItem @click="showEmployeeShiftDetail(employeeShift)">
                        <Info class="mr-2 h-4 w-4" />Detail
                      </DropdownMenuItem>
                      <DropdownMenuItem @click="editEmployeeShift(employeeShift)">
                        <Edit class="mr-2 h-4 w-4" />Edit
                      </DropdownMenuItem>
                      <DropdownMenuItem @click="confirmDeleteEmployeeShift(employeeShift.id)">
                        <Trash2 class="mr-2 h-4 w-4" />Hapus
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </TableCell>
              </TableRow>
            </TableBody>
          </Table>
          <div
            v-if="employeeShifts.length === 0 && !loading"
            class="text-center text-gray-500 dark:text-gray-400 mt-4"
          >
            Tidak ada jadwal shift karyawan ditemukan.
          </div>
        </CardContent>
      </Card>

      <!-- Delete Confirmation Dialog -->
      <Dialog :open="isConfirmDeleteOpen" @update:open="isConfirmDeleteOpen = $event">
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Konfirmasi Hapus Jadwal Shift</DialogTitle>
            <DialogDescription>
              Apakah Anda yakin ingin menghapus jadwal shift ini? Tindakan ini tidak dapat
              dibatalkan.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" @click="isConfirmDeleteOpen = false">Batal</Button>
            <Button
              variant="destructive"
              @click="deleteEmployeeShiftConfirmed"
              :disabled="loading"
            >
              <span v-if="loading">Menghapus...</span>
              <span v-else>Hapus</span>
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <!-- Employee Shift Detail Dialog -->
      <Dialog :open="isEmployeeShiftDetailOpen" @update:open="isEmployeeShiftDetailOpen = $event">
        <DialogContent class="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Detail Jadwal Shift Karyawan</DialogTitle>
            <DialogDescription>Informasi lengkap mengenai jadwal shift karyawan ini.</DialogDescription>
          </DialogHeader>
          <div v-if="selectedEmployeeShift" class="grid gap-4 py-4">
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailEmployeeName" class="text-right">Karyawan</Label>
              <Input id="detailEmployeeName" :model-value="selectedEmployeeShift.employee_name" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailShiftName" class="text-right">Shift</Label>
              <Input id="detailShiftName" :model-value="`${selectedEmployeeShift.shift_name} (${selectedEmployeeShift.shift_start_time} - ${selectedEmployeeShift.shift_end_time})`" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailDayOfWeek" class="text-right">Hari</Label>
              <Input id="detailDayOfWeek" :model-value="getDayName(selectedEmployeeShift.day_of_week)" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailIsActive" class="text-right">Aktif</Label>
              <div class="col-span-3">
                <Badge :variant="selectedEmployeeShift.is_active ? 'success' : 'destructive'">
                  {{ selectedEmployeeShift.is_active ? "Ya" : "Tidak" }}
                </Badge>
              </div>
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailCreatedAt" class="text-right">Dibuat Pada</Label>
              <Input id="detailCreatedAt" :model-value="formatDate(selectedEmployeeShift.created_at)" readonly class="col-span-3" />
            </div>
          </div>
          <DialogFooter>
            <DialogClose as-child>
              <Button type="button" variant="outline">Tutup</Button>
            </DialogClose>
            <Button @click="editEmployeeShift(selectedEmployeeShift!)">
              <Edit class="mr-2 h-4 w-4" />Edit Jadwal Shift
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
    <Toaster />
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  title: 'Employee Shifts - Aplikasi Kasir'
})
import { ref, onMounted, computed, watch } from "vue";
import { useSupabaseClient, useSupabaseUser } from "#imports";
import { toast } from 'vue-sonner';
import { Toaster } from '@/components/ui/sonner';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea"; // Added for consistency with categories.vue
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
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
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

interface EmployeeShift {
  id: string;
  employee_id: string;
  employee_name?: string; // Joined from profiles
  shift_id: string;
  shift_name?: string; // Joined from shifts
  shift_start_time?: string; // Joined from shifts
  shift_end_time?: string; // Joined from shifts
  day_of_week: number;
  is_active: boolean;
  created_at: string;
}

interface EmployeeProfile {
  id: string;
  full_name: string;
}

interface Shift {
  id: string;
  name: string;
  start_time: string;
  end_time: string;
  is_active: boolean;
}

const supabase = useSupabaseClient();
const user = useSupabaseUser();

const employeeShifts = ref<EmployeeShift[]>([]);
const employees = ref<EmployeeProfile[]>([]);
const shifts = ref<Shift[]>([]);

const employeeShiftForm = ref({
  id: "",
  employee_id: "",
  shift_id: "",
  day_of_week: 0, // 0=Sunday, 1=Monday, etc.
  is_active: true,
});
const pageLoading = ref(true); // New ref for overall page loading
const isEditing = ref(false);
const loading = ref(false);
const hasAdminOrManagerRole = ref(false);
const isEmployeeShiftFormOpen = ref(false); // Controls the add/edit employee shift dialog
const isConfirmDeleteOpen = ref(false); // Controls the delete confirmation dialog
const employeeShiftToDeleteId = ref<string | null>(null); // Stores the ID of the employee shift to be deleted
const isEmployeeShiftDetailOpen = ref(false); // Controls the employee shift detail dialog
const selectedEmployeeShift = ref<EmployeeShift | null>(null); // Stores the selected employee shift for detail view

const fetchEmployeeShifts = async () => {
  loading.value = true;
  try {
    const { data, error } = await supabase
      .from("employee_shifts")
      .select(
        `
        *,
        profiles!employee_shifts_employee_id_fkey(full_name),
        shifts!employee_shifts_shift_id_fkey(name, start_time, end_time, total_work_hours)
      `
      )
      .order("day_of_week", { ascending: true });

    if (error) throw error;

    employeeShifts.value = data.map((es: any) => ({
      ...es,
      employee_name: es.profiles?.full_name || "N/A",
      shift_name: es.shifts?.name || "N/A",
      shift_start_time: es.shifts?.start_time || "N/A",
      shift_end_time: es.shifts?.end_time || "N/A",
      shift_total_work_hours: es.shifts?.total_work_hours || null, // Include total_work_hours
      is_active: Boolean(es.is_active), // Ensure is_active is a boolean
      profiles: undefined,
      shifts: undefined,
    })) as EmployeeShift[];
  } catch (error: any) {
    toast.error("Gagal memuat jadwal shift karyawan!", {
      description: error.message,
    });
  } finally {
    loading.value = false;
  }
};

const fetchEmployees = async () => {
  try {
    const { data, error } = await supabase
      .from("profiles")
      .select("id, full_name")
      .in("role", ["admin", "manager", "cashier"])
      .order("full_name", { ascending: true });

    if (error) throw error;
    employees.value = data as EmployeeProfile[];
  } catch (error: any) {
    console.error("Error fetching employees:", error.message);
  }
};

const fetchShifts = async () => {
  try {
    const { data, error } = await supabase
      .from("shifts")
      .select("*")
      .order("name", { ascending: true });

    if (error) throw error;
    shifts.value = data as Shift[];
  } catch (error: any) {
    console.error("Error fetching shifts:", error.message);
  }
};

const activeShifts = computed(() => {
  return shifts.value.filter((shift) => shift.is_active);
});

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

const saveEmployeeShift = async () => {
  loading.value = true;
  try {
    if (isEditing.value) {
      const { error } = await supabase
        .from("employee_shifts")
        .update({
          shift_id: employeeShiftForm.value.shift_id,
          is_active: employeeShiftForm.value.is_active,
        })
        .eq("id", employeeShiftForm.value.id);
      if (error) throw error;
      toast.success("Jadwal shift berhasil diperbarui!", {
        description: `Jadwal shift untuk ${employeeShiftForm.value.employee_id} telah berhasil diperbarui.`,
      });
    } else {
      const { error } = await supabase.from("employee_shifts").insert({
        employee_id: employeeShiftForm.value.employee_id,
        shift_id: employeeShiftForm.value.shift_id,
        day_of_week: employeeShiftForm.value.day_of_week,
        is_active: employeeShiftForm.value.is_active,
      });
      if (error) throw error;
      toast.success("Jadwal shift berhasil ditambahkan!", {
        description: `Jadwal shift baru telah berhasil ditambahkan.`,
      });
    }
    resetForm();
    await fetchEmployeeShifts();
    isEmployeeShiftFormOpen.value = false; // Close the dialog on success
  } catch (error: any) {
    toast.error("Gagal menyimpan jadwal shift!", {
      description: error.message,
    });
  } finally {
    loading.value = false;
  }
};

const addNewEmployeeShift = () => {
  resetForm();
  isEmployeeShiftFormOpen.value = true;
};

const editEmployeeShift = (employeeShift: EmployeeShift) => {
  isEditing.value = true;
  employeeShiftForm.value = {
    ...employeeShift,
    is_active: Boolean(employeeShift.is_active), // Ensure is_active is a boolean
  };
  isEmployeeShiftFormOpen.value = true; // Open the dialog for editing
  isEmployeeShiftDetailOpen.value = false; // Close detail dialog if open
};

const cancelEdit = () => {
  resetForm();
  isEmployeeShiftFormOpen.value = false; // Close the dialog on cancel
};

const confirmDeleteEmployeeShift = (id: string) => {
  employeeShiftToDeleteId.value = id;
  isEmployeeShiftFormOpen.value = false; // Close the employee shift form dialog
  isConfirmDeleteOpen.value = true;
};

const deleteEmployeeShiftConfirmed = async () => {
  if (!employeeShiftToDeleteId.value) return;

  loading.value = true;
  try {
    const { error } = await supabase
      .from("employee_shifts")
      .delete()
      .eq("id", employeeShiftToDeleteId.value);
    if (error) throw error;
    loading.value = false; // Set loading to false before closing dialog
    isConfirmDeleteOpen.value = false; // Close the confirmation dialog
    employeeShiftToDeleteId.value = null; // Clear the ID
    toast.success("Jadwal shift berhasil dihapus!", {
      description: "Jadwal shift telah berhasil dihapus dari daftar.",
    });
    await fetchEmployeeShifts();
  } catch (error: any) {
    toast.error("Gagal menghapus jadwal shift!", {
      description: error.message,
    });
  } finally {
    loading.value = false;
  }
};

const resetForm = () => {
  isEditing.value = false;
  employeeShiftForm.value = {
    id: "",
    employee_id: "",
    shift_id: "",
    day_of_week: 0,
    is_active: true,
  };
};

const getDayName = (dayOfWeek: number) => {
  const days = ["Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"];
  return days[dayOfWeek];
};

const showEmployeeShiftDetail = (employeeShift: EmployeeShift) => {
  selectedEmployeeShift.value = employeeShift;
  isEmployeeShiftDetailOpen.value = true;
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
      await fetchEmployees();
      await fetchShifts();
      await fetchEmployeeShifts();
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
    // No need to set pageLoading here, as this watch is for reactive changes after initial load
    // The initial load is handled by onMounted
    await checkUserRole();
    if (hasAdminOrManagerRole.value) {
      await fetchEmployees();
      await fetchShifts();
      await fetchEmployeeShifts();
    }
  } else {
    hasAdminOrManagerRole.value = false;
    employeeShifts.value = [];
    employees.value = [];
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
