<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-2 sm:p-4">
    <!-- Header Section -->
    <div class="mb-4">
        <h1 class="text-2xl sm:text-3xl font-bold mb-4 sm:mb-6 text-gray-900 dark:text-white">
      Absensi Karyawan
    </h1>
    </div>

    <div v-if="pageLoading" class="flex justify-center items-center h-[60vh]">
      <div class="flex flex-col gap-4">
        <div class="spinner"></div>
      </div>
    </div>

    <div v-else-if="!hasAccessRole" class="flex flex-col items-center justify-center h-[60vh] gap-4">
      <div class="p-4 bg-red-50 dark:bg-red-900/20 rounded-lg">
        <p class="text-red-500 dark:text-red-400 text-center">
          Anda tidak memiliki izin untuk mengakses halaman ini.
        </p>
      </div>
    </div>

    <div v-else class="space-y-4">
      <!-- Quick Stats Cards -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardHeader class="pb-2">
            <CardTitle class="text-xl font-medium text-gray-500 dark:text-gray-400">
              Status Hari Ini
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div class="flex items-center gap-2">
              <Badge :variant="todayAttendance?.status ? getStatusVariant(todayAttendance.status) : 'outline'">
                {{ todayAttendance?.status || 'Belum Absen' }}
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
                {{ todayAttendance?.check_in ? formatTime(todayAttendance.check_in) : '-' }}
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
                {{ todayAttendance?.check_out ? formatTime(todayAttendance.check_out) : '-' }}
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
                {{ todayAttendance?.total_hours ? `${todayAttendance.total_hours} jam` : '-' }}
              </span>
            </div>
          </CardContent>
        </Card>
      </div>

      <!-- Check-in/Check-out Actions -->
      <Card>
        <CardHeader>
          <CardTitle>Absensi Hari Ini</CardTitle>
          <CardDescription>Lakukan check-in dan check-out dengan foto selfie</CardDescription>
        </CardHeader>
        <CardContent>
          <div v-if="hasActiveShiftToday" class="mb-4">
            <p>
              <b>Shift Hari Ini:</b>
              {{ employeeShifts[0].shifts.name }} ({{ employeeShifts[0].shifts.start_time }} - {{ employeeShifts[0].shifts.end_time }})
            </p>
          </div>
          <div v-else class="mb-4 p-4 bg-yellow-100 text-yellow-800 rounded">
            Anda tidak memiliki jadwal shift aktif hari ini. Silakan hubungi admin/manager untuk penjadwalan shift.
          </div>
          <div class="flex flex-col sm:flex-row gap-4">
            <Button
              @click="openCamera('check_in')"
              :disabled="loadingAttendance || !!todayAttendance || !hasActiveShiftToday"
              class="flex-1 text-lg py-3"
              size="xl"
            >
              <UserIcon class="mr-2 h-5 w-5" />
              <span v-if="loadingAttendance">Memproses...</span>
              <span v-else>Check-in</span>
            </Button>
            <Button
              @click="openCamera('check_out')"
              :disabled="loadingAttendance || !todayAttendance?.check_in || !!todayAttendance?.check_out || !hasActiveShiftToday"
              class="flex-1 text-lg py-3"
              size="xl"
              variant="secondary"
            >
              <UserIcon class="mr-2 h-5 w-5" />
              <span v-if="loadingAttendance">Memproses...</span>
              <span v-else>Check-out</span>
            </Button>
            <Button
              @click="openOtherAttendanceModal"
              :disabled="loadingAttendance || !!todayAttendance || !hasActiveShiftToday"
              class="flex-1 text-lg py-3"
              size="xl"
              variant="outline"
            >
              <UserIcon class="mr-2 h-5 w-5" />
              Ajukan Absen Lain
            </Button>
          </div>

          <div v-if="todayAttendance" class="mt-6 grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Attendance Details -->
            <div class="space-y-4">
              <div class="flex justify-between items-center py-2 border-b dark:border-gray-700">
                <span class="text-lg text-gray-500 dark:text-gray-400">Tanggal</span>
                <span class="text-lg font-medium">{{ formatDate(todayAttendance.date) }}</span>
              </div>
              <div class="flex justify-between items-center py-2 border-b dark:border-gray-700">
                <span class="text-lg text-gray-500 dark:text-gray-400">Status</span>
                <Badge :variant="getStatusVariant(todayAttendance.status)">
                  {{ todayAttendance.status }}
                </Badge>
              </div>
            </div>

            <!-- Photo Evidence -->
            <div class="space-y-4">
              <div class="grid grid-cols-2 gap-4">
                <div class="space-y-2">
                  <Label class="text-base">Foto Check-in</Label>
                  <div class="relative aspect-square rounded-lg overflow-hidden bg-gray-100 dark:bg-gray-800">
                    <img
                      v-if="todayAttendance.check_in_photo_url"
                      :src="todayAttendance.check_in_photo_url"
                      alt="Check-in photo"
                      class="object-cover w-full h-full"
                    />
                    <div v-else class="flex items-center justify-center h-full text-gray-400">
                      Belum ada foto
                    </div>
                  </div>
                </div>
                <div class="space-y-2">
                  <Label class="text-base">Foto Check-out</Label>
                  <div class="relative aspect-square rounded-lg overflow-hidden bg-gray-100 dark:bg-gray-800">
                    <img
                      v-if="todayAttendance.check_out_photo_url"
                      :src="todayAttendance.check_out_photo_url"
                      alt="Check-out photo"
                      class="object-cover w-full h-full"
                    />
                    <div v-else class="flex items-center justify-center h-full text-gray-400">
                      Belum ada foto
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      <!-- Personal Attendance History -->
      <Card>
        <CardHeader>
          <CardTitle>Riwayat Absensi Pribadi</CardTitle>
          <CardDescription>Catatan kehadiran Anda selama bekerja</CardDescription>
        </CardHeader>
        <CardContent>
          <div class="relative overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead class="text-base">Tanggal</TableHead>
                  <TableHead class="text-base">Check-in</TableHead>
                  <TableHead class="text-base">Check-out</TableHead>
                  <TableHead class="text-base">Total Jam</TableHead>
                  <TableHead class="text-base">Status</TableHead>
                  <TableHead class="text-base">Foto</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                <TableRow v-for="record in personalAttendanceHistory" :key="record.id">
                  <TableCell class="text-base">{{ formatDate(record.date) }}</TableCell>
                  <TableCell class="text-base">{{ record.check_in ? formatTime(record.check_in) : "-" }}</TableCell>
                  <TableCell class="text-base">{{ record.check_out ? formatTime(record.check_out) : "-" }}</TableCell>
                  <TableCell class="text-base">{{ record.total_hours || "-" }}</TableCell>
                  <TableCell>
                    <Badge :variant="getStatusVariant(record.status)">{{ record.status }}</Badge>
                  </TableCell>
                  <TableCell>
                    <div class="flex gap-2">
                      <Button
                        v-if="record.check_in_photo_url"
                        variant="outline"
                        @click="openPhotoUrl(record.check_in_photo_url)"
                      >
                        In
                      </Button>
                      <Button
                        v-if="record.check_out_photo_url"
                        variant="outline"
                        @click="openPhotoUrl(record.check_out_photo_url)"
                      >
                        Out
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
                <TableRow v-if="personalAttendanceHistory.length === 0 && !loadingPersonalHistory">
                  <TableCell colspan="6" class="text-center py-8 text-lg text-gray-500 dark:text-gray-400">
                    Tidak ada riwayat absensi.
                  </TableCell>
                </TableRow>
              </TableBody>
            </Table>
            </div>
          </CardContent>
        </Card>
      </div>

    </div>

    <!-- Camera Modal -->
    <Dialog :open="showCameraModal" @update:open="showCameraModal = $event">
      <DialogContent class="sm:max-w-[600px]">
        <DialogHeader>
          <DialogTitle>
            Ambil Foto untuk {{ cameraType === 'check_in' ? 'Check-in' : 'Check-out' }}
          </DialogTitle>
          <DialogDescription>
            Pastikan wajah Anda terlihat jelas di kamera.
          </DialogDescription>
        </DialogHeader>
        <div class="space-y-4">
          <div v-if="!capturedImage" class="relative aspect-video rounded-lg overflow-hidden bg-gray-100 dark:bg-gray-800">
            <WebcamCapture ref="webcamRef" :width="560" :height="420" :mirror="true" />
          </div>
          <div v-else class="relative aspect-video rounded-lg overflow-hidden bg-gray-100 dark:bg-gray-800">
            <img :src="capturedImage" alt="Captured Image" class="object-cover w-full h-full" />
          </div>
          <div class="flex justify-end gap-2">
            <Button v-if="!capturedImage" @click="captureImage" size="lg">
              Ambil Foto
            </Button>
            <Button v-else @click="capturedImage = null" variant="outline" size="lg">
              Ambil Ulang
            </Button>
            <Button
              v-if="capturedImage"
              @click="handleAttendanceAction(cameraType!)"
              :disabled="uploadingPhoto"
              size="lg"
            >
              <span v-if="uploadingPhoto">Mengunggah...</span>
              <span v-else>Konfirmasi & Absen</span>
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>

    <!-- Other Attendance Modal -->
    <Dialog :open="showOtherAttendanceModal" @update:open="showOtherAttendanceModal = $event">
      <DialogContent class="sm:max-w-[600px]">
        <DialogHeader>
          <DialogTitle>Ajukan Absen Lain</DialogTitle>
          <DialogDescription>
            Ajukan status absensi selain check-in/check-out.
          </DialogDescription>
        </DialogHeader>
        <form @submit.prevent="handleOtherAttendanceSubmission" class="space-y-4">
          <div class="space-y-2">
            <Label>Status Absensi</Label>
            <Select v-model="otherAttendanceForm.status">
              <SelectTrigger>
                <SelectValue placeholder="Pilih Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="sick">Sakit</SelectItem>
                <SelectItem value="permission">Izin</SelectItem>
                <SelectItem value="absent">Tidak Hadir</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div class="space-y-2">
            <Label>Catatan (Opsional)</Label>
            <Textarea v-model="otherAttendanceForm.notes" placeholder="Tambahkan catatan..." />
          </div>
          <DialogFooter>
            <Button type="submit" :disabled="loadingAttendance" size="lg">
              <span v-if="loadingAttendance">Mengajukan...</span>
              <span v-else>Ajukan Absen</span>
            </Button>
            <Button type="button" variant="outline" @click="showOtherAttendanceModal = false" size="lg">
              Batal
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>

    <!-- Edit Attendance Modal -->
    <Dialog :open="showEditModal" @update:open="showEditModal = $event">
      <DialogContent class="sm:max-w-[600px]">
        <DialogHeader>
          <DialogTitle>Edit Absensi</DialogTitle>
          <DialogDescription>
            Perbarui detail absensi karyawan.
          </DialogDescription>
        </DialogHeader>
        <form @submit.prevent="saveEditedAttendance" class="space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="space-y-2">
              <Label>Karyawan</Label>
              <Input :value="editForm.employee_name" disabled />
            </div>
            <div class="space-y-2">
              <Label>Tanggal</Label>
              <Input type="date" v-model="editForm.date" disabled />
            </div>
            <div class="space-y-2">
              <Label>Check-in</Label>
              <Input type="datetime-local" v-model="editForm.check_in" />
            </div>
            <div class="space-y-2">
              <Label>Check-out</Label>
              <Input type="datetime-local" v-model="editForm.check_out" />
            </div>
            <div class="space-y-2">
              <Label>Total Jam Kerja</Label>
              <Input type="number" step="0.01" v-model.number="editForm.total_hours" />
            </div>
            <div class="space-y-2">
              <Label>Status</Label>
              <Select v-model="editForm.status">
                <SelectTrigger>
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
          </div>
          <div class="space-y-2">
            <Label>Catatan</Label>
            <Textarea v-model="editForm.notes" />
          </div>
          <DialogFooter>
            <Button type="submit" :disabled="loadingEdit" size="lg">
              <span v-if="loadingEdit">Menyimpan...</span>
              <span v-else>Simpan</span>
            </Button>
            <Button type="button" variant="outline" @click="resetEditForm" size="lg">
              Batal
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>

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
          <Button variant="outline" @click="isConfirmDeleteOpen = false" size="lg">
            Batal
          </Button>
          <Button
            variant="destructive"
            @click="deleteAttendanceConfirmed"
            :disabled="loadingAllHistory"
            size="lg"
          >
            <span v-if="loadingAllHistory">Menghapus...</span>
            <span v-else>Hapus</span>
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

    <!-- Toaster for notifications -->
    <Toaster />


  <!-- Half-Day Confirmation Dialog -->
  <Dialog :open="showHalfDayConfirmationModal" @update:open="showHalfDayConfirmationModal = $event">
    <DialogContent>
      <DialogHeader>
        <DialogTitle>Konfirmasi Check-out Setengah Hari</DialogTitle>
        <DialogDescription>
          Total jam kerja Anda hari ini adalah {{ halfDayConfirmationData?.totalHours }} jam. Ini kurang dari jam kerja penuh yang seharusnya ({{ FULL_WORK_HOURS }} jam).
          Apakah Anda yakin ingin check-out dengan status "Setengah Hari"?
        </DialogDescription>
      </DialogHeader>
      <DialogFooter>
        <Button variant="outline" @click="showHalfDayConfirmationModal = false">Batal</Button>
        <Button @click="confirmHalfDayCheckout">Lanjutkan Check-out</Button>
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
import { CalendarIcon, ClockIcon, UserIcon } from 'lucide-vue-next' // Added ClockIcon, UserIcon

import { ref, onMounted, computed, watch, onUnmounted } from "vue"; // Added onUnmounted
import { useSupabaseClient, useSupabaseUser } from "#imports";
import WebcamCapture from "@/components/WebcamCapture.vue";
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
  TableCaption, // Added TableCaption
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
import { toast } from 'vue-sonner'; // For notifications
import { Toaster } from '@/components/ui/sonner';
import 'vue-sonner/style.css';
import {
} from "@/components/ui/card";

interface Attendance {
  id: string;
  employee_id: string;
  employee_name?: string; // Joined from profiles
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
const employeeShifts = ref<any[]>([]); // To store employee's assigned shifts

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

// Constants for attendance logic (will be dynamically fetched)
const OFFICIAL_CHECK_IN_TIME = ref("09:00:00"); // Default, will be overridden by shift
const FULL_WORK_HOURS = ref(8); // Default, will be overridden by shift
const HALF_WORK_HOURS_THRESHOLD = computed(() => FULL_WORK_HOURS.value / 2);

interface Shift {
  id: string;
  name: string;
  start_time: string;
  end_time: string;
  is_active: boolean;
  total_work_hours: number; // New field for total work hours
}


const showCameraModal = ref(false);
const cameraType = ref<'check_in' | 'check_out' | null>(null);
const capturedImage = ref<string | null>(null);
const webcamRef = ref<InstanceType<typeof WebcamCapture> | null>(null);
const uploadingPhoto = ref(false);

const showOtherAttendanceModal = ref(false);
const otherAttendanceForm = ref({
  status: "sick", // Default status
  notes: "",
});

const showHalfDayConfirmationModal = ref(false);
const halfDayConfirmationData = ref<{
  totalHours: number | null;
  originalStatus: "present" | "absent" | "late" | "half_day" | "sick" | "permission" | "leave" | "remote";
  checkInTime: Date;
  photoUrl: string;
} | null>(null);

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
  check_in_photo_url: null,
  check_out_photo_url: null,
  total_hours: null,
  status: "present",
  notes: null,
});

const openOtherAttendanceModal = () => {
  otherAttendanceForm.value = {
    status: "sick",
    notes: "",
  };
  showOtherAttendanceModal.value = true;
};

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

const fetchEmployeeShiftsForUser = async () => {
  if (!user.value) return;
  try {
    const today = new Date();
    const dayOfWeek = today.getDay(); // 0 for Sunday, 1 for Monday, etc.

    const { data, error } = await supabase
      .from("employee_shifts")
      .select(
        `
        *,
        shifts!employee_shifts_shift_id_fkey(name, start_time, end_time, total_work_hours)
        `
      )
      .eq("employee_id", user.value.id)
      .eq("day_of_week", dayOfWeek)
      .eq("is_active", true)
      .single();

    if (error && error.code !== "PGRST116") {
      throw error;
    }

    if (data) {
      employeeShifts.value = [data]; // Store the active shift for today
      OFFICIAL_CHECK_IN_TIME.value = data.shifts?.start_time || "09:00:00";
      FULL_WORK_HOURS.value = data.shifts?.total_work_hours || 8;
    } else {
      employeeShifts.value = [];
      // Reset to defaults if no active shift found for today
      OFFICIAL_CHECK_IN_TIME.value = "09:00:00";
      FULL_WORK_HOURS.value = 8;
    }
  } catch (error: any) {
    console.error("Error fetching employee shifts:", error.message);
    toast.error("Gagal memuat jadwal shift karyawan!", {
      description: error.message,
    });
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

const openCamera = (type: 'check_in' | 'check_out') => {
  cameraType.value = type;
  capturedImage.value = null;
  showCameraModal.value = true;
};

const captureImage = () => {
  if (webcamRef.value) {
    capturedImage.value = webcamRef.value.capture();
  }
};

const uploadImage = async () => {
  if (!capturedImage.value || !user.value) return;

  uploadingPhoto.value = true;
  try {
    const byteCharacters = atob(capturedImage.value.split(',')[1]);
    const byteNumbers = new Array(byteCharacters.length);
    for (let i = 0; i < byteCharacters.length; i++) {
      byteNumbers[i] = byteCharacters.charCodeAt(i);
    }
    const byteArray = new Uint8Array(byteNumbers);
    const blob = new Blob([byteArray], { type: 'image/jpeg' });

    const fileName = `${user.value.id}-${cameraType.value}-${Date.now()}.jpeg`;
    const filePath = `attendance_photos/${fileName}`;

    const { error: uploadError } = await supabase.storage
      .from('attendance_photos')
      .upload(filePath, blob, {
        cacheControl: '3600',
        upsert: false,
      });

    if (uploadError) throw uploadError;

    const { data: publicUrlData } = supabase.storage
      .from('attendance_photos')
      .getPublicUrl(filePath);

    if (!publicUrlData || !publicUrlData.publicUrl) {
      throw new Error('Failed to get public URL for the uploaded image.');
    }

    return publicUrlData.publicUrl;
  } catch (error: any) {
    toast.error("Gagal mengunggah foto", {
      description: error.message,
    });
    return null;
  } finally {
    uploadingPhoto.value = false;
  }
};

const performCheckoutUpdate = async (photoUrl: string, totalHours: number | null, originalStatus: Attendance['status']) => {
  if (!user.value || !todayAttendance.value?.id) return;

  loadingAttendance.value = true;
  try {
    let statusToUpdate = originalStatus;
    let notesToUpdate = todayAttendance.value.notes;

    // Determine final status based on totalHours and originalStatus
    if (totalHours !== null && totalHours < FULL_WORK_HOURS.value) {
      statusToUpdate = "half_day";
      // If original status was 'late', add a note about it
      if (originalStatus === "late") {
        const checkInDateTime = new Date(todayAttendance.value.check_in || '');
        const officialCheckInTimeParts = OFFICIAL_CHECK_IN_TIME.value.split(':');
        const officialCheckInDateTime = new Date(checkInDateTime);
        officialCheckInDateTime.setHours(parseInt(officialCheckInTimeParts[0]), parseInt(officialCheckInTimeParts[1]), parseInt(officialCheckInTimeParts[2] || '0'), 0);

        const lateDiffMs = checkInDateTime.getTime() - officialCheckInDateTime.getTime();
        const lateMinutes = Math.ceil(lateDiffMs / (1000 * 60)); // Round up to nearest minute

        const lateNote = ` (Telat ${lateMinutes} menit saat check-in)`;
        notesToUpdate = notesToUpdate ? `${notesToUpdate}${lateNote}` : lateNote;
      }
    }

    const { data, error } = await supabase
      .from("attendance")
      .update({
        check_out: new Date().toISOString(),
        check_out_photo_url: photoUrl,
        total_hours: totalHours,
        status: statusToUpdate,
        notes: notesToUpdate,
        updated_at: new Date().toISOString(),
      })
      .eq("id", todayAttendance.value.id)
      .select("*")
      .single();

    if (error) throw error;
    todayAttendance.value = data as Attendance;
    toast.success("Check-out berhasil!", {
      description: `Anda telah berhasil check-out dengan status: ${statusToUpdate === 'half_day' ? 'Setengah Hari' : (statusToUpdate === 'late' ? 'Terlambat' : 'Hadir')}.`,
    });
    await fetchPersonalAttendanceHistory();
    showCameraModal.value = false;
    capturedImage.value = null;
  } catch (error: any) {
    toast.error(`Gagal Check-out`, {
      description: error.message,
    });
  } finally {
    loadingAttendance.value = false;
  }
};

const confirmHalfDayCheckout = async () => {
  if (!halfDayConfirmationData.value) return;

  showHalfDayConfirmationModal.value = false; // Close the confirmation modal
  await performCheckoutUpdate(
    halfDayConfirmationData.value.photoUrl,
    halfDayConfirmationData.value.totalHours,
    halfDayConfirmationData.value.originalStatus
  );
  halfDayConfirmationData.value = null; // Clear data
};

const handleAttendanceAction = async (actionType: 'check_in' | 'check_out') => {
  if (!user.value) return;
  if (!hasActiveShiftToday.value) {
    toast.error("Anda tidak memiliki jadwal shift aktif hari ini.");
    return;
  }

  loadingAttendance.value = true;
  attendanceMessage.value = "";
  attendanceError.value = false;
  successMessage.value = "";

  try {
    const photoUrl = await uploadImage();
    if (!photoUrl) {
      throw new Error("Gagal mengunggah foto.");
    }

    const now = new Date();
    const today = now.toISOString().split("T")[0];

    if (actionType === 'check_in') {
      const { data, error } = await supabase
        .from("attendance")
        .insert({
          employee_id: user.value.id,
          date: today,
          check_in: now.toISOString(),
          check_in_photo_url: photoUrl,
          status: "present", // Default status, will be updated if late
        })
        .select("*")
        .single();

      if (error) throw error;

      // Check for late check-in
      const checkInDateTime = new Date(now.toISOString());
      const officialCheckInTimeParts = OFFICIAL_CHECK_IN_TIME.value.split(':');
      const officialCheckInDateTime = new Date(now);
      officialCheckInDateTime.setHours(parseInt(officialCheckInTimeParts[0]), parseInt(officialCheckInTimeParts[1]), parseInt(officialCheckInTimeParts[2] || '0'), 0);

      let status = "present";
      if (checkInDateTime > officialCheckInDateTime) {
        status = "late";
      }

      // Update status if late
      const { data: updatedCheckInData, error: updateError } = await supabase
        .from("attendance")
        .update({ status: status, updated_at: new Date().toISOString() })
        .eq("id", data.id)
        .select("*")
        .single();

      if (updateError) throw updateError;

      todayAttendance.value = updatedCheckInData as Attendance;
      toast.success("Check-in berhasil!", {
        description: `Anda telah berhasil check-in dengan status: ${status === 'late' ? 'Terlambat' : 'Hadir'}.`,
      });
    } else { // actionType === 'check_out'
      if (!todayAttendance.value?.id) {
        throw new Error("Anda belum check-in hari ini.");
      }
      const checkInTime = new Date(todayAttendance.value.check_in || now);
      const diffMs = now.getTime() - checkInTime.getTime();
      const totalHours = parseFloat((diffMs / (1000 * 60 * 60)).toFixed(2));

      if (totalHours < FULL_WORK_HOURS.value) {
        halfDayConfirmationData.value = {
          totalHours,
          originalStatus: todayAttendance.value.status,
          checkInTime,
          photoUrl,
        };
        showHalfDayConfirmationModal.value = true;
        return; // Stop here, wait for user confirmation
      }

      // If not half-day, proceed directly with checkout
      await performCheckoutUpdate(photoUrl, totalHours, todayAttendance.value.status);
    }
  } catch (error: any) {
    toast.error(`Gagal ${actionType === 'check_in' ? 'Check-in' : 'Check-out'}`, {
      description: error.message,
    });
  } finally {
    loadingAttendance.value = false;
  }
};

const handleOtherAttendanceSubmission = async () => {
  if (!user.value) return;
  if (!hasActiveShiftToday.value) {
    toast.error("Anda tidak memiliki jadwal shift aktif hari ini.");
    return;
  }

  loadingAttendance.value = true;
  attendanceMessage.value = "";
  attendanceError.value = false;
  successMessage.value = "";

  try {
    const today = new Date().toISOString().split("T")[0];

    // Check if attendance already exists for today
    const { data: existingAttendance, error: existingError } = await supabase
      .from("attendance")
      .select("id")
      .eq("employee_id", user.value.id)
      .eq("date", today)
      .single();

    if (existingError && existingError.code !== "PGRST116") {
      throw existingError;
    }

    if (existingAttendance) {
      throw new Error("Anda sudah memiliki catatan absensi untuk hari ini. Silakan gunakan fitur edit jika ingin mengubah status.");
    }

    const { data, error } = await supabase
      .from("attendance")
      .insert({
        employee_id: user.value.id,
        date: today,
        status: otherAttendanceForm.value.status,
        notes: otherAttendanceForm.value.notes || null,
      })
      .select("*")
      .single();

    if (error) throw error;
    todayAttendance.value = data as Attendance;
    toast.success("Absen berhasil diajukan!", {
      description: `Status Anda hari ini: ${otherAttendanceForm.value.status}.`,
    });
    await fetchPersonalAttendanceHistory();
    showOtherAttendanceModal.value = false;
  } catch (error: any) {
    toast.error("Gagal mengajukan absen", {
      description: error.message,
    });
  } finally {
    loadingAttendance.value = false;
  }
};


const resetEditForm = () => {
  editForm.value = {
    id: "",
    employee_id: "",
    employee_name: "",
    date: "",
    check_in: null,
    check_out: null,
    check_in_photo_url: null,
    check_out_photo_url: null,
    total_hours: null,
    status: "present",
    notes: null,
  };
  showEditModal.value = false;
  editErrorMessage.value = "";
};



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
      return "info"; // Assuming 'info' variant exists or can be mapped
    case "remote":
      return "success"; // Assuming 'success' variant exists or can be mapped
    default:
      return "default";
  }
};

const openPhotoUrl = (url: string | null) => {
  if (url && process.client) {
    window.open(url, '_blank');
  }
};

const hasActiveShiftToday = computed(() => {
  return employeeShifts.value.length > 0;
});

onMounted(async () => {
  pageLoading.value = true; // Start loading
  try {
    await checkUserRole();
    if (hasAccessRole.value) {
      await fetchEmployeeShiftsForUser(); // Fetch employee's shift for today
      await fetchTodayAttendance();
      await fetchPersonalAttendanceHistory();
    }
  } catch (error: any) {
    toast.error("Terjadi kesalahan saat memuat data awal!", {
      description: error.message,
    });
  } finally {
    pageLoading.value = false; // End loading
  }
});

watch([user], async ([newUser]) => {
  if (newUser) {
    // No need to set pageLoading here, as this watch is for reactive changes after initial load
    // The initial load is handled by onMounted
    await checkUserRole();
    if (hasAccessRole.value) {
      await fetchTodayAttendance();
      await fetchPersonalAttendanceHistory();
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
