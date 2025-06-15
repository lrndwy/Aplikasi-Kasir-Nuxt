<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-4">
    <h1 class="text-3xl font-bold mb-6 text-gray-900 dark:text-white">
      Manajemen Absensi Karyawan
    </h1>

    <div v-if="pageLoading" class="flex justify-center items-center h-64">
      <div class="spinner"></div>
    </div>

    <div v-else-if="!hasAccessRole" class="text-center text-red-500 dark:text-red-400">
      Anda tidak memiliki izin untuk mengakses halaman ini.
    </div>

    <div v-else>
      <!-- Check-in/Check-out Section -->
      <div class="bg-white dark:bg-gray-800 shadow-md rounded-lg p-6 mb-6">
        <h2 class="text-2xl font-semibold mb-4 text-gray-900 dark:text-white">
          Absensi Hari Ini
        </h2>
        <div class="flex flex-wrap gap-2">
          <Button
            @click="checkIn"
            :disabled="loadingAttendance || !!todayAttendance?.check_in"
            class="w-full sm:w-auto"
          >
            <span v-if="loadingAttendance">Memproses...</span>
            <span v-else>Check-in</span>
          </Button>
          <Button
            @click="checkOut"
            :disabled="
              loadingAttendance ||
              !todayAttendance?.check_in ||
              !!todayAttendance?.check_out
            "
            class="w-full sm:w-auto"
          >
            <span v-if="loadingAttendance">Memproses...</span>
            <span v-else>Check-out</span>
          </Button>
          <Button
            @click="startBreak"
            :disabled="
              loadingAttendance ||
              !todayAttendance?.check_in ||
              !!todayAttendance?.break_start
            "
            class="w-full sm:w-auto"
          >
            <span v-if="loadingAttendance">Memproses...</span>
            <span v-else>Mulai Istirahat</span>
          </Button>
          <Button
            @click="endBreak"
            :disabled="
              loadingAttendance ||
              !todayAttendance?.break_start ||
              !!todayAttendance?.break_end
            "
            class="w-full sm:w-auto"
          >
            <span v-if="loadingAttendance">Memproses...</span>
            <span v-else>Akhiri Istirahat</span>
          </Button>
        </div>
        <div v-if="attendanceMessage" class="text-sm mt-4">
          <div
            :class="{
              'text-green-500': !attendanceError,
              'text-red-500': attendanceError,
            }"
          >
            {{ attendanceMessage }}
          </div>
        </div>
        <div v-if="successMessage" class="text-green-500 text-sm mt-4">
          {{ successMessage }}
        </div>
        <div v-if="successMessage" class="text-green-500 text-sm mt-4">
          {{ successMessage }}
        </div>
        <div
          v-if="todayAttendance"
          class="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4 text-gray-700 dark:text-gray-300"
        >
          <div class="flex items-center">
            <strong class="w-1/2">Tanggal:</strong>
            <span class="w-1/2">{{ formatDate(todayAttendance.date) }}</span>
          </div>
          <div class="flex items-center">
            <strong class="w-1/2">Check-in:</strong>
            <span class="w-1/2">{{
              todayAttendance.check_in ? formatTime(todayAttendance.check_in) : "-"
            }}</span>
          </div>
          <div class="flex items-center">
            <strong class="w-1/2">Check-out:</strong>
            <span class="w-1/2">{{
              todayAttendance.check_out ? formatTime(todayAttendance.check_out) : "-"
            }}</span>
          </div>
          <div class="flex items-center">
            <strong class="w-1/2">Mulai Istirahat:</strong>
            <span class="w-1/2">{{
              todayAttendance.break_start ? formatTime(todayAttendance.break_start) : "-"
            }}</span>
          </div>
          <div class="flex items-center">
            <strong class="w-1/2">Akhir Istirahat:</strong>
            <span class="w-1/2">{{
              todayAttendance.break_end ? formatTime(todayAttendance.break_end) : "-"
            }}</span>
          </div>
          <div class="flex items-center">
            <strong class="w-1/2">Total Jam Kerja:</strong>
            <span class="w-1/2">{{ todayAttendance.total_hours || "-" }}</span>
          </div>
          <div class="flex items-center">
            <strong class="w-1/2">Status:</strong>
            <span class="w-1/2">
              <Badge :variant="getStatusVariant(todayAttendance.status)">{{
                todayAttendance.status
              }}</Badge>
            </span>
          </div>
        </div>
      </div>

      <!-- Personal Attendance History -->
      <div class="bg-white dark:bg-gray-800 shadow-md rounded-lg p-6 mb-6">
        <h2 class="text-2xl font-semibold mb-4 text-gray-900 dark:text-white">
          Riwayat Absensi Pribadi
        </h2>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Tanggal</TableHead>
              <TableHead>Check-in</TableHead>
              <TableHead>Check-out</TableHead>
              <TableHead>Istirahat</TableHead>
              <TableHead>Total Jam</TableHead>
              <TableHead>Status</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            <TableRow v-for="record in personalAttendanceHistory" :key="record.id">
              <TableCell>{{ formatDate(record.date) }}</TableCell>
              <TableCell>{{
                record.check_in ? formatTime(record.check_in) : "-"
              }}</TableCell>
              <TableCell>{{
                record.check_out ? formatTime(record.check_out) : "-"
              }}</TableCell>
              <TableCell>{{
                record.break_start && record.break_end
                  ? `${formatTime(record.break_start)} - ${formatTime(record.break_end)}`
                  : "-"
              }}</TableCell>
              <TableCell>{{ record.total_hours || "-" }}</TableCell>
              <TableCell
                ><Badge :variant="getStatusVariant(record.status)">{{
                  record.status
                }}</Badge></TableCell
              >
            </TableRow>
            <TableRow
              v-if="personalAttendanceHistory.length === 0 && !loadingPersonalHistory"
            >
              <TableCell colspan="6" class="text-center text-gray-500 dark:text-gray-400">
                Tidak ada riwayat absensi.
              </TableCell>
            </TableRow>
          </TableBody>
        </Table>
        <div
          v-if="loadingPersonalHistory"
          class="text-center text-gray-500 dark:text-gray-400 mt-4"
        >
          Memuat riwayat absensi...
        </div>
      </div>

      <!-- Admin/Manager Section: All Employee Attendance -->
      <div
        v-if="hasAdminOrManagerRole"
        class="bg-white dark:bg-gray-800 shadow-md rounded-lg p-6"
      >
        <h2 class="text-2xl font-semibold mb-4 text-gray-900 dark:text-white">
          Riwayat Absensi Semua Karyawan
        </h2>
        <div class="mb-4 flex flex-col sm:flex-row gap-4">
          <Input
            v-model="searchEmployeeQuery"
            placeholder="Cari nama karyawan..."
            class="w-full sm:w-1/3"
          />
          <Popover>
            <PopoverTrigger as-child>
              <Button
                variant="outline"
                :class="
                  cn(
                    'w-full sm:w-1/4 justify-start text-left font-normal',
                    !filterDate && 'text-muted-foreground'
                  )
                "
              >
                <CalendarIcon class="mr-2 h-4 w-4" />
                {{
                  filterDate
                    ? df.format(filterDate.toDate(getLocalTimeZone()))
                    : "Filter Tanggal"
                }}
              </Button>
            </PopoverTrigger>
            <PopoverContent class="w-auto p-0">
              <Calendar v-model="filterDate" initial-focus />
            </PopoverContent>
          </Popover>
          <Select v-model="filterStatusAll" class="w-full sm:w-1/4">
            <SelectTrigger>
              <SelectValue
                :placeholder="
                  filterStatusAll === 'all' ? 'Filter Status' : filterStatusAll
                "
              />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Semua Status</SelectItem>
              <SelectItem value="present">Present</SelectItem>
              <SelectItem value="absent">Absent</SelectItem>
              <SelectItem value="late">Late</SelectItem>
              <SelectItem value="half_day">Half Day</SelectItem>
              <SelectItem value="sick">Sick</SelectItem>
              <SelectItem value="permission">Permission</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Karyawan</TableHead>
              <TableHead>Tanggal</TableHead>
              <TableHead>Check-in</TableHead>
              <TableHead>Check-out</TableHead>
              <TableHead>Total Jam</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Catatan</TableHead>
              <TableHead>Aksi</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            <TableRow v-for="record in filteredAllAttendance" :key="record.id">
              <TableCell>{{ record.employee_name }}</TableCell>
              <TableCell>{{ formatDate(record.date) }}</TableCell>
              <TableCell>{{
                record.check_in ? formatTime(record.check_in) : "-"
              }}</TableCell>
              <TableCell>{{
                record.check_out ? formatTime(record.check_out) : "-"
              }}</TableCell>
              <TableCell>{{ record.total_hours || "-" }}</TableCell>
              <TableCell
                ><Badge :variant="getStatusVariant(record.status)">{{
                  record.status
                }}</Badge></TableCell
              >
              <TableCell>{{ record.notes || "-" }}</TableCell>
              <TableCell>
                <Button
                  variant="outline"
                  size="sm"
                  @click="editAttendance(record)"
                  class="mr-2"
                  >Edit</Button
                >
                <Button
                  variant="destructive"
                  size="sm"
                  @click="confirmDeleteAttendance(record.id)"
                  >Hapus</Button
                >
              </TableCell>
            </TableRow>
            <TableRow v-if="filteredAllAttendance.length === 0 && !loadingAllHistory">
              <TableCell colspan="8" class="text-center text-gray-500 dark:text-gray-400">
                Tidak ada riwayat absensi karyawan.
              </TableCell>
            </TableRow>
          </TableBody>
        </Table>
        <div
          v-if="loadingAllHistory"
          class="text-center text-gray-500 dark:text-gray-400 mt-4"
        >
          Memuat riwayat absensi semua karyawan...
        </div>
      </div>
    </div>

    <!-- Edit Attendance Modal (for Admin/Manager) -->
    <Dialog :open="showEditModal" @update:open="showEditModal = $event">
      <DialogContent class="sm:max-w-[600px] p-6">
        <DialogHeader>
          <DialogTitle>Edit Absensi</DialogTitle>
          <DialogDescription>Perbarui detail absensi karyawan.</DialogDescription>
        </DialogHeader>
        <form @submit.prevent="saveEditedAttendance" class="space-y-4 py-4">
          <div>
            <Label>Karyawan:</Label>
            <Input :value="editForm.employee_name" disabled />
          </div>
          <div>
            <Label>Tanggal:</Label>
            <Input type="date" v-model="editForm.date" disabled />
          </div>
          <div>
            <Label for="editCheckIn">Check-in</Label>
            <Input id="editCheckIn" type="datetime-local" v-model="editForm.check_in" />
          </div>
          <div>
            <Label for="editCheckOut">Check-out</Label>
            <Input id="editCheckOut" type="datetime-local" v-model="editForm.check_out" />
          </div>
          <div>
            <Label for="editBreakStart">Mulai Istirahat</Label>
            <Input
              id="editBreakStart"
              type="datetime-local"
              v-model="editForm.break_start"
            />
          </div>
          <div>
            <Label for="editBreakEnd">Akhir Istirahat</Label>
            <Input id="editBreakEnd" type="datetime-local" v-model="editForm.break_end" />
          </div>
          <div>
            <Label for="editTotalHours">Total Jam Kerja</Label>
            <Input
              id="editTotalHours"
              type="number"
              step="0.01"
              v-model.number="editForm.total_hours"
            />
          </div>
          <div>
            <Label for="editStatus">Status</Label>
            <Select v-model="editForm.status">
              <SelectTrigger id="editStatus">
                <SelectValue :placeholder="editForm.status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="present">Present</SelectItem>
                <SelectItem value="absent">Absent</SelectItem>
                <SelectItem value="late">Late</SelectItem>
                <SelectItem value="half_day">Half Day</SelectItem>
                <SelectItem value="sick">Sick</SelectItem>
                <SelectItem value="permission">Permission</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div>
            <Label for="editNotes">Catatan</Label>
            <Textarea id="editNotes" v-model="editForm.notes" />
          </div>
          <DialogFooter>
            <Button type="submit" :disabled="loadingEdit">
              <span v-if="loadingEdit">Menyimpan...</span>
              <span v-else>Simpan</span>
            </Button>
            <DialogClose as-child>
              <Button type="button" variant="outline" @click="resetEditForm()"
                >Batal</Button
              >
            </DialogClose>
          </DialogFooter>
          <div v-if="editErrorMessage" class="text-red-500 text-sm mt-4">
            {{ editErrorMessage }}
          </div>
        </form>
      </DialogContent>
    </Dialog>
  </div>

  <!-- Delete Confirmation Dialog -->
  <Dialog :open="isConfirmDeleteOpen" @update:open="isConfirmDeleteOpen = $event">
    <DialogContent>
      <DialogHeader>
        <DialogTitle>Konfirmasi Hapus Absensi</DialogTitle>
        <DialogDescription>
          Apakah Anda yakin ingin menghapus catatan absensi ini? Tindakan ini tidak dapat
          dibatalkan.
        </DialogDescription>
      </DialogHeader>
      <DialogFooter>
        <Button variant="outline" @click="isConfirmDeleteOpen = false">Batal</Button>
        <Button
          variant="destructive"
          @click="deleteAttendanceConfirmed"
          :disabled="loadingAllHistory"
        >
          <span v-if="loadingAllHistory">Menghapus...</span>
          <span v-else>Hapus</span>
        </Button>
      </DialogFooter>
    </DialogContent>
  </Dialog>
</template>

<script setup lang="ts">
definePageMeta({
  title: 'Attendance - Aplikasi Kasir'
})
import {
  DateFormatter,
  type DateValue,
  getLocalTimeZone,
} from '@internationalized/date'
import { CalendarIcon } from 'lucide-vue-next'

import { ref, onMounted, computed, watch } from "vue";
import { useSupabaseClient, useSupabaseUser } from "#imports";
import { cn } from '@/lib/utils';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
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
import { Badge } from "@/components/ui/badge";
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
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";

interface Attendance {
  id: string;
  employee_id: string;
  employee_name?: string; // Joined from profiles
  date: string;
  check_in: string | null;
  check_out: string | null;
  break_start: string | null;
  break_end: string | null;
  total_hours: number | null;
  status: "present" | "absent" | "late" | "half_day" | "sick" | "permission";
  notes: string | null;
  created_at: string;
  updated_at: string;
}

interface EmployeeProfile {
  id: string;
  full_name: string;
}

const supabase = useSupabaseClient();
const user = useSupabaseUser();

const todayAttendance = ref<Attendance | null>(null);
const personalAttendanceHistory = ref<Attendance[]>([]);
const allAttendanceHistory = ref<Attendance[]>([]);
const employees = ref<EmployeeProfile[]>([]);

const pageLoading = ref(true); // New ref for overall page loading
const loadingAttendance = ref(false);
const loadingPersonalHistory = ref(false);
const loadingAllHistory = ref(false);
const loadingEdit = ref(false);

const attendanceMessage = ref("");
const attendanceError = ref(false);
const errorMessage = ref("");
const editErrorMessage = ref("");
const successMessage = ref("");

const hasAccessRole = ref(false); // Cashier, Admin, Manager
const hasAdminOrManagerRole = ref(false); // Admin, Manager

const df = new DateFormatter('en-US', {
  dateStyle: 'long',
});

const searchEmployeeQuery = ref("");
const filterDate = ref<DateValue | undefined>();
const filterStatusAll = ref("");

const isConfirmDeleteOpen = ref(false); // Controls the delete confirmation dialog
const attendanceToDeleteId = ref<string | null>(null); // Stores the ID of the attendance record to be deleted

const showEditModal = ref(false);
const editForm = ref<Partial<Attendance> & { employee_name?: string }>({
  id: "",
  employee_id: "",
  employee_name: "",
  date: "",
  check_in: null,
  check_out: null,
  break_start: null,
  break_end: null,
  total_hours: null,
  status: "present",
  notes: null,
});

const fetchTodayAttendance = async () => {
  if (!user.value) return;
  loadingAttendance.value = true;
  attendanceMessage.value = "";
  attendanceError.value = false;
  successMessage.value = "";
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
    attendanceMessage.value = "Gagal memuat absensi hari ini: " + error.message;
    attendanceError.value = true;
  } finally {
    loadingAttendance.value = false;
  }
};

const fetchPersonalAttendanceHistory = async () => {
  if (!user.value) return;
  loadingPersonalHistory.value = true;
  try {
    const { data, error } = await supabase
      .from("attendance")
      .select("*")
      .eq("employee_id", user.value.id)
      .order("date", { ascending: false });

    if (error) throw error;
    personalAttendanceHistory.value = data as Attendance[];
  } catch (error: any) {
    console.error("Error fetching personal attendance history:", error.message);
  } finally {
    loadingPersonalHistory.value = false;
  }
};

const fetchAllAttendanceHistory = async () => {
  if (!hasAdminOrManagerRole.value) return;
  loadingAllHistory.value = true;
  errorMessage.value = "";
  try {
    let query = supabase
      .from("attendance")
      .select(
        `
        *,
        profiles!attendance_employee_id_fkey(full_name)
      `
      )
      .order("date", { ascending: false })
      .order("created_at", { ascending: false });

    if (filterDate.value) {
      query = query.eq("date", filterDate.value.toString());
    }
    if (filterStatusAll.value && filterStatusAll.value !== "all") {
      query = query.eq("status", filterStatusAll.value);
    }

    const { data, error } = await query;

    if (error) throw error;

    allAttendanceHistory.value = data.map((a: any) => ({
      ...a,
      employee_name: a.profiles?.full_name || "N/A",
      profiles: undefined,
    })) as Attendance[];
  } catch (error: any) {
    errorMessage.value = error.message;
  } finally {
    loadingAllHistory.value = false;
  }
};

const fetchEmployees = async () => {
  if (!hasAdminOrManagerRole.value) return;
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

const checkUserRole = async () => {
  if (!user.value) {
    hasAccessRole.value = false;
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
    hasAccessRole.value = false;
    hasAdminOrManagerRole.value = false;
    return;
  }
  hasAccessRole.value =
    data.role === "admin" || data.role === "manager" || data.role === "cashier";
  hasAdminOrManagerRole.value = data.role === "admin";

  if (!hasAccessRole.value) {
    errorMessage.value = "Anda tidak memiliki izin untuk mengakses halaman ini.";
  }
};

const checkIn = async () => {
  if (!user.value) return;
  loadingAttendance.value = true;
  attendanceMessage.value = "";
  attendanceError.value = false;
  successMessage.value = "";
  try {
    const now = new Date();
    const today = now.toISOString().split("T")[0];

    const { data, error } = await supabase
      .from("attendance")
      .insert({
        employee_id: user.value.id,
        date: today,
        check_in: now.toISOString(),
        status: "present",
      })
      .select("*")
      .single();

    if (error) throw error;
    todayAttendance.value = data as Attendance;
    successMessage.value = "Check-in berhasil!";
    await fetchPersonalAttendanceHistory();
  } catch (error: any) {
    attendanceMessage.value = "Gagal check-in: " + error.message;
    attendanceError.value = true;
  } finally {
    loadingAttendance.value = false;
  }
};

const checkOut = async () => {
  if (!user.value || !todayAttendance.value?.id) return;
  loadingAttendance.value = true;
  attendanceMessage.value = "";
  attendanceError.value = false;
  successMessage.value = "";
  try {
    const now = new Date();
    const checkInTime = new Date(todayAttendance.value.check_in || now);
    let totalHours = null;

    if (checkInTime) {
      const diffMs = now.getTime() - checkInTime.getTime();
      totalHours = parseFloat((diffMs / (1000 * 60 * 60)).toFixed(2));
    }

    const { data, error } = await supabase
      .from("attendance")
      .update({
        check_out: now.toISOString(),
        total_hours: totalHours,
        updated_at: new Date().toISOString(),
      })
      .eq("id", todayAttendance.value.id)
      .select("*")
      .single();

    if (error) throw error;
    todayAttendance.value = data as Attendance;
    successMessage.value = "Check-out berhasil!";
    await fetchPersonalAttendanceHistory();
  } catch (error: any) {
    attendanceMessage.value = "Gagal check-out: " + error.message;
    attendanceError.value = true;
  } finally {
    loadingAttendance.value = false;
  }
};

const startBreak = async () => {
  if (!user.value || !todayAttendance.value?.id) return;
  loadingAttendance.value = true;
  attendanceMessage.value = "";
  attendanceError.value = false;
  successMessage.value = "";
  try {
    const { data, error } = await supabase
      .from("attendance")
      .update({
        break_start: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq("id", todayAttendance.value.id)
      .select("*")
      .single();

    if (error) throw error;
    todayAttendance.value = data as Attendance;
    successMessage.value = "Mulai istirahat berhasil!";
  } catch (error: any) {
    attendanceMessage.value = "Gagal memulai istirahat: " + error.message;
    attendanceError.value = true;
  } finally {
    loadingAttendance.value = false;
  }
};

const endBreak = async () => {
  if (!user.value || !todayAttendance.value?.id || !todayAttendance.value?.break_start)
    return;
  loadingAttendance.value = true;
  attendanceMessage.value = "";
  attendanceError.value = false;
  successMessage.value = "";
  try {
    const { data, error } = await supabase
      .from("attendance")
      .update({
        break_end: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq("id", todayAttendance.value.id)
      .select("*")
      .single();

    if (error) throw error;
    todayAttendance.value = data as Attendance;
    successMessage.value = "Akhir istirahat berhasil!";
  } catch (error: any) {
    attendanceMessage.value = "Gagal mengakhiri istirahat: " + error.message;
    attendanceError.value = true;
  } finally {
    loadingAttendance.value = false;
  }
};

const editAttendance = (record: Attendance) => {
  editForm.value = {
    ...record,
    employee_name:
      employees.value.find((emp) => emp.id === record.employee_id)?.full_name || "N/A",
    check_in: record.check_in
      ? new Date(record.check_in).toISOString().slice(0, 16)
      : null,
    check_out: record.check_out
      ? new Date(record.check_out).toISOString().slice(0, 16)
      : null,
    break_start: record.break_start
      ? new Date(record.break_start).toISOString().slice(0, 16)
      : null,
    break_end: record.break_end
      ? new Date(record.break_end).toISOString().slice(0, 16)
      : null,
  };
  showEditModal.value = true;
  editErrorMessage.value = "";
};

const resetEditForm = () => {
  editForm.value = {
    id: "",
    employee_id: "",
    employee_name: "",
    date: "",
    check_in: null,
    check_out: null,
    break_start: null,
    break_end: null,
    total_hours: null,
    status: "present",
    notes: null,
  };
  showEditModal.value = false;
  editErrorMessage.value = "";
};

const saveEditedAttendance = async () => {
  loadingEdit.value = true;
  editErrorMessage.value = "";
  try {
    const { id, employee_name, ...updateData } = editForm.value; // Exclude id and employee_name
    const { error } = await supabase
      .from("attendance")
      .update({
        ...updateData,
        updated_at: new Date().toISOString(),
      })
      .eq("id", id);

    if (error) throw error;
    resetEditForm(); // Close the dialog and reset form on success
    await fetchAllAttendanceHistory(); // Refresh all attendance data
  } catch (error: any) {
    editErrorMessage.value = "Gagal menyimpan perubahan: " + error.message;
  } finally {
    loadingEdit.value = false;
  }
};

const confirmDeleteAttendance = (id: string) => {
  attendanceToDeleteId.value = id;
  isConfirmDeleteOpen.value = true;
};

const deleteAttendanceConfirmed = async () => {
  if (!attendanceToDeleteId.value) return;

  loadingAllHistory.value = true;
  errorMessage.value = "";
  try {
    const { error } = await supabase
      .from("attendance")
      .delete()
      .eq("id", attendanceToDeleteId.value);
    if (error) throw error;
    await fetchAllAttendanceHistory();
    isConfirmDeleteOpen.value = false; // Close the confirmation dialog
    attendanceToDeleteId.value = null; // Clear the ID
  } catch (error: any) {
    errorMessage.value = error.message;
  } finally {
    loadingAllHistory.value = false;
  }
};

const filteredAllAttendance = computed(() => {
  let filtered = allAttendanceHistory.value;

  if (searchEmployeeQuery.value) {
    const query = searchEmployeeQuery.value.toLowerCase();
    filtered = filtered.filter((record) =>
      record.employee_name?.toLowerCase().includes(query)
    );
  }

  return filtered;
});

const formatDate = (dateString: string) => {
  const options: Intl.DateTimeFormatOptions = {
    year: "numeric",
    month: "long",
    day: "numeric",
  };
  return new Date(dateString).toLocaleDateString("id-ID", options);
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
  status: "present" | "absent" | "late" | "half_day" | "sick" | "permission"
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
    default:
      return "default";
  }
};

onMounted(async () => {
  pageLoading.value = true; // Start loading
  try {
    await checkUserRole();
    if (hasAccessRole.value) {
      await fetchTodayAttendance();
      await fetchPersonalAttendanceHistory();
      if (hasAdminOrManagerRole.value) {
        await fetchEmployees();
        await fetchAllAttendanceHistory();
      }
    }
  } finally {
    pageLoading.value = false; // End loading
  }
});

watch([user, filterDate, filterStatusAll], async ([newUser]) => {
  if (newUser) {
    // No need to set pageLoading here, as this watch is for reactive changes after initial load
    // The initial load is handled by onMounted
    await checkUserRole();
    if (hasAccessRole.value) {
      await fetchTodayAttendance();
      await fetchPersonalAttendanceHistory();
      if (hasAdminOrManagerRole.value) {
        await fetchEmployees();
        await fetchAllAttendanceHistory();
      }
    }
  } else {
    hasAccessRole.value = false;
    hasAdminOrManagerRole.value = false;
    todayAttendance.value = null;
    personalAttendanceHistory.value = [];
    allAttendanceHistory.value = [];
    employees.value = [];
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
