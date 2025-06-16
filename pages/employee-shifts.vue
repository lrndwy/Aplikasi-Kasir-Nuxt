<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-4">
    <h1 class="text-3xl font-bold mb-6 text-gray-900 dark:text-white">
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
                  <SelectTrigger id="employeeSelect">
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
                  <SelectTrigger id="shiftSelect">
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
                  <SelectTrigger id="dayOfWeek">
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
                  v-model:checked="employeeShiftForm.is_active"
                />
                <Label for="employeeShiftIsActive">Aktif</Label>
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
                  <span v-else>{{
                    isEditing ? "Perbarui Jadwal" : "Tetapkan Jadwal"
                  }}</span>
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

      <!-- Daftar Jadwal Shift Karyawan -->
      <div class="bg-white dark:bg-gray-800 shadow-md rounded-lg p-6">
        <h2 class="text-2xl font-semibold mb-4 text-gray-900 dark:text-white">
          Daftar Jadwal Shift
        </h2>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Karyawan</TableHead>
              <TableHead>Shift</TableHead>
              <TableHead>Hari</TableHead>
              <TableHead>Aktif</TableHead>
              <TableHead>Aksi</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            <TableRow v-for="employeeShift in employeeShifts" :key="employeeShift.id">
              <TableCell>{{ employeeShift.employee_name }}</TableCell>
              <TableCell
                >{{ employeeShift.shift_name }} ({{ employeeShift.shift_start_time }} -
                {{ employeeShift.shift_end_time }})</TableCell
              >
              <TableCell>{{ getDayName(employeeShift.day_of_week) }}</TableCell>
              <TableCell>{{ employeeShift.is_active ? "Ya" : "Tidak" }}</TableCell>
              <TableCell>
                <Button
                  variant="outline"
                  size="sm"
                  @click="editEmployeeShift(employeeShift)"
                  class="mr-2"
                  >Edit</Button
                >
                <Button
                  variant="destructive"
                  size="sm"
                  @click="confirmDeleteEmployeeShift(employeeShift.id)"
                  >Hapus</Button
                >
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
      </div>

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
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  title: 'Employee Shifts - Aplikasi Kasir'
})
import { ref, onMounted, computed, watch } from "vue";
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
const errorMessage = ref("");
const successMessage = ref("");
const hasAdminOrManagerRole = ref(false);
const isEmployeeShiftFormOpen = ref(false); // Controls the add/edit employee shift dialog
const isConfirmDeleteOpen = ref(false); // Controls the delete confirmation dialog
const employeeShiftToDeleteId = ref<string | null>(null); // Stores the ID of the employee shift to be deleted

const fetchEmployeeShifts = async () => {
  loading.value = true;
  errorMessage.value = "";
  try {
    const { data, error } = await supabase
      .from("employee_shifts")
      .select(
        `
        *,
        profiles!employee_shifts_employee_id_fkey(full_name),
        shifts!employee_shifts_shift_id_fkey(name, start_time, end_time)
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
      profiles: undefined,
      shifts: undefined,
    })) as EmployeeShift[];
  } catch (error: any) {
    errorMessage.value = error.message;
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
    console.error("Error fetching user role:", error.message);
    hasAdminOrManagerRole.value = false;
    return;
  }
  hasAdminOrManagerRole.value = data.role === "admin" || data.role === "manager";
  if (!hasAdminOrManagerRole.value) {
    errorMessage.value = "Anda tidak memiliki izin untuk mengakses halaman ini.";
  }
};

const saveEmployeeShift = async () => {
  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";
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
      successMessage.value = "Jadwal shift berhasil diperbarui!";
    } else {
      const { error } = await supabase.from("employee_shifts").insert({
        employee_id: employeeShiftForm.value.employee_id,
        shift_id: employeeShiftForm.value.shift_id,
        day_of_week: employeeShiftForm.value.day_of_week,
        is_active: employeeShiftForm.value.is_active,
      });
      if (error) throw error;
      successMessage.value = "Jadwal shift berhasil ditambahkan!";
    }
    resetForm();
    await fetchEmployeeShifts();
    isEmployeeShiftFormOpen.value = false; // Close the dialog on success
  } catch (error: any) {
    errorMessage.value = error.message;
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
  employeeShiftForm.value = { ...employeeShift };
  errorMessage.value = "";
  successMessage.value = "";
  isEmployeeShiftFormOpen.value = true; // Open the dialog for editing
};

const cancelEdit = () => {
  resetForm();
  isEmployeeShiftFormOpen.value = false; // Close the dialog on cancel
};

const confirmDeleteEmployeeShift = (id: string) => {
  employeeShiftToDeleteId.value = id;
  isConfirmDeleteOpen.value = true;
};

const deleteEmployeeShiftConfirmed = async () => {
  if (!employeeShiftToDeleteId.value) return;

  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";
  try {
    const { error } = await supabase
      .from("employee_shifts")
      .delete()
      .eq("id", employeeShiftToDeleteId.value);
    if (error) throw error;
    successMessage.value = "Jadwal shift berhasil dihapus!";
    await fetchEmployeeShifts();
    isConfirmDeleteOpen.value = false; // Close the confirmation dialog
    employeeShiftToDeleteId.value = null; // Clear the ID
  } catch (error: any) {
    errorMessage.value = error.message;
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

onMounted(async () => {
  pageLoading.value = true; // Start loading
  try {
    await checkUserRole();
    if (hasAdminOrManagerRole.value) {
      await fetchEmployees();
      await fetchShifts();
      await fetchEmployeeShifts();
    }
  } finally {
    pageLoading.value = false; // End loading
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
