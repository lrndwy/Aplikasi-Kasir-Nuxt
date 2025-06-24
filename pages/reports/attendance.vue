<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-4">
    <h1 class="text-3xl font-bold mb-6 text-gray-900 dark:text-white">
      Laporan Absensi Karyawan
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
      <Card class="mb-6">
        <CardHeader>
          <CardTitle>Filter Laporan</CardTitle>
        </CardHeader>
        <CardContent>
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div>
              <Label for="employeeFilter" class="mb-2">Filter Karyawan</Label>
              <Select v-model="selectedEmployeeId">
                <SelectTrigger id="employeeFilter" class="bg-white dark:bg-gray-950 w-full">
                  <SelectValue
                    :placeholder="
                      selectedEmployeeId
                        ? employees.find((e) => e.id === selectedEmployeeId)?.full_name
                        : 'Semua Karyawan'
                    "
                  />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem :value="null">Semua Karyawan</SelectItem>
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
              <Label for="startDate" class="mb-2">Tanggal Mulai</Label>
              <Popover>
                <PopoverTrigger as-child class="hover:bg-white">
                  <Button
                    variant="outline"
                    :class="
                      cn(
                        'w-full justify-start text-left font-normal',
                        !startDate && 'text-muted-foreground'
                      )
                    "
                  >
                    <CalendarIcon class="mr-2 h-4 w-4" />
                    {{
                      startDate
                        ? df.format(startDate.toDate(getLocalTimeZone()))
                        : "Pilih tanggal"
                    }}
                  </Button>
                </PopoverTrigger>
                <PopoverContent class="w-auto p-0">
                  <Calendar v-model="startDate" initial-focus />
                </PopoverContent>
              </Popover>
            </div>
            <div>
              <Label for="endDate" class="mb-2">Tanggal Akhir</Label>
              <Popover>
                <PopoverTrigger as-child class="hover:bg-white">
                  <Button
                    variant="outline"
                    :class="
                      cn(
                        'w-full justify-start text-left font-normal',
                        !endDate && 'text-muted-foreground'
                      )
                    "
                  >
                    <CalendarIcon class="mr-2 h-4 w-4" />
                    {{
                      endDate ? df.format(endDate.toDate(getLocalTimeZone())) : "Pilih tanggal"
                    }}
                  </Button>
                </PopoverTrigger>
                <PopoverContent class="w-auto p-0">
                  <Calendar v-model="endDate" initial-focus />
                </PopoverContent>
              </Popover>
            </div>
            <div>
              <Label for="statusFilter" class="mb-2">Status Absensi</Label>
              <Select v-model="attendanceStatusFilter">
                <SelectTrigger id="statusFilter" class="bg-white dark:bg-gray-950 w-full">
                  <SelectValue
                    :placeholder="
                      attendanceStatusFilter === null
                        ? 'Semua Status'
                        : attendanceStatusFilter
                    "
                  />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem :value="null">Semua Status</SelectItem>
                  <SelectItem value="present">Hadir</SelectItem>
                  <SelectItem value="absent">Tidak Hadir</SelectItem>
                  <SelectItem value="late">Terlambat</SelectItem>
                  <SelectItem value="half_day">Setengah Hari</SelectItem>
                  <SelectItem value="sick">Sakit</SelectItem>
                  <SelectItem value="permission">Izin</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardContent>
      </Card>

      <div v-if="errorMessage" class="text-red-500 text-sm mb-4">
        {{ errorMessage }}
      </div>

      <Card v-if="selectedEmployeeId && selectedEmployeeName" class="mb-6">
        <CardHeader>
          <CardTitle>Ringkasan Absensi untuk {{ selectedEmployeeName }}</CardTitle>
        </CardHeader>
        <CardContent>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4 text-gray-800 dark:text-gray-200">
            <div class="flex items-center gap-2">
              <CalendarDaysIcon class="h-6 w-6 text-blue-500" />
              <div>
                <p class="text-sm font-medium">Total Hari Kerja:</p>
                <p class="text-lg font-bold">{{ summaryStats[selectedEmployeeId]?.total_days || 0 }}</p>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <CheckCircleIcon class="h-6 w-6 text-green-600" />
              <div>
                <p class="text-sm font-medium">Hadir:</p>
                <p class="text-lg font-bold text-green-600">{{ summaryStats[selectedEmployeeId]?.present || 0 }}</p>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <ClockIcon class="h-6 w-6 text-yellow-600" />
              <div>
                <p class="text-sm font-medium">Terlambat:</p>
                <p class="text-lg font-bold text-yellow-600">{{ summaryStats[selectedEmployeeId]?.total_lateness_minutes || 0 }} menit</p>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <XCircleIcon class="h-6 w-6 text-red-500" />
              <div>
                <p class="text-sm font-medium">Tidak Hadir:</p>
                <p class="text-lg font-bold text-red-500">{{ summaryStats[selectedEmployeeId]?.absent || 0 }}</p>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <StethoscopeIcon class="h-6 w-6 text-purple-500" />
              <div>
                <p class="text-sm font-medium">Sakit:</p>
                <p class="text-lg font-bold text-purple-500">{{ summaryStats[selectedEmployeeId]?.sick || 0 }}</p>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <FileTextIcon class="h-6 w-6 text-orange-500" />
              <div>
                <p class="text-sm font-medium">Izin:</p>
                <p class="text-lg font-bold text-orange-500">{{ summaryStats[selectedEmployeeId]?.permission || 0 }}</p>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      <!-- Attendance Details Table -->
      <Card>
        <CardHeader>
          <CardTitle>Detail Absensi {{ selectedEmployeeName ? `untuk ${selectedEmployeeName}` : '' }}</CardTitle>
        </CardHeader>
        <CardContent>
          <div class="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead v-if="!selectedEmployeeId">Karyawan</TableHead>
                  <TableHead>Tanggal</TableHead>
                  <TableHead>Check-in</TableHead>
                  <TableHead>Check-out</TableHead>
                  <TableHead>Total Jam</TableHead>
                  <TableHead>Total Keterlambatan (menit)</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Catatan</TableHead>
                  <TableHead>Foto</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                <TableRow v-for="record in attendanceData" :key="record.id">
                  <TableCell v-if="!selectedEmployeeId">{{ record.employee_name }}</TableCell>
                  <TableCell>{{ formatDate(record.date) }}</TableCell>
                  <TableCell>{{
                    record.check_in ? formatTime(record.check_in) : "-"
                  }}</TableCell>
                  <TableCell>{{
                    record.check_out ? formatTime(record.check_out) : "-"
                  }}</TableCell>
                  <TableCell>{{ record.total_hours || "-" }}</TableCell>
                  <TableCell>{{ record.total_lateness_minutes !== null ? record.total_lateness_minutes : "-" }}</TableCell>
                  <TableCell>
                    <div class="flex items-center gap-2">
                      <XCircleIcon v-if="record.status === 'absent'" class="h-4 w-4 text-red-500" />
                      <StethoscopeIcon v-if="record.status === 'sick'" class="h-4 w-4 text-purple-500" />
                      <FileTextIcon v-if="record.status === 'permission'" class="h-4 w-4 text-orange-500" />
                      <Badge :variant="getStatusVariant(record.status)">
                        {{ record.status }}
                      </Badge>
                    </div>
                  </TableCell>
                  <TableCell>{{ record.notes || "-" }}</TableCell>
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
                <TableRow v-if="attendanceData.length === 0 && !loading">
                  <TableCell :colspan="selectedEmployeeId ? 7 : 8" class="text-center text-gray-500 dark:text-gray-400">
                    Tidak ada data absensi untuk kriteria ini.
                  </TableCell>
                </TableRow>
              </TableBody>
            </Table>
          </div>
          <div v-if="loading" class="text-center text-gray-500 dark:text-gray-400 mt-4">
            Memuat data absensi...
          </div>
        </CardContent>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import {
  DateFormatter,
  type DateValue,
  getLocalTimeZone,
} from '@internationalized/date'
import { CalendarIcon, CalendarDaysIcon, CheckCircleIcon, ClockIcon, XCircleIcon, StethoscopeIcon, FileTextIcon, HomeIcon, BriefcaseIcon } from 'lucide-vue-next'

import { ref, onMounted, watch } from "vue";
import { useSupabaseClient, useSupabaseUser } from "#imports";
import { cn } from '@/lib/utils';
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

interface Attendance {
  id: string;
  employee_id: string;
  employee_name?: string;
  date: string;
  check_in: string | null;
  check_out: string | null;
  check_in_photo_url: string | null;
  check_out_photo_url: string | null;
  total_hours: number | null;
  total_lateness_minutes: number | null;
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

const attendanceData = ref<Attendance[]>([]);
const employees = ref<EmployeeProfile[]>([]);

const df = new DateFormatter('en-US', {
  dateStyle: 'long',
});

const pageLoading = ref(true);
const selectedEmployeeId = ref<string | null>(null);
const startDate = ref<DateValue | undefined>();
const endDate = ref<DateValue | undefined>();
const attendanceStatusFilter = ref<string | null>(null);

const selectedEmployeeName = ref<string | null>(null);
const summaryStats = ref<{ [key: string]: { present: number; absent: number; late: number; sick: number; permission: number; total_days: number; total_lateness_minutes: number } }>({});

const loading = ref(false);
const errorMessage = ref("");
const hasAdminOrManagerRole = ref(false);

const fetchAttendanceData = async () => {
  loading.value = true;
  errorMessage.value = "";
  let employeeShiftsData: any[] = [];
  let shiftsData: any[] = [];

  try {
    let query = supabase
      .from("attendance")
      .select(
        `
        *,
        *,
        *,
        profiles!attendance_employee_id_fkey(full_name)
      `
      )
      .order("date", { ascending: false })
      .order("created_at", { ascending: false });

    if (selectedEmployeeId.value) {
      query = query.eq("employee_id", selectedEmployeeId.value);
    }
    if (startDate.value) {
      query = query.gte("date", startDate.value.toString());
    }
    if (endDate.value) {
      query = query.lte("date", endDate.value.toString());
    }
    if (attendanceStatusFilter.value) {
      query = query.eq("status", attendanceStatusFilter.value);
    }

    const { data, error } = await query;

    if (error) throw error;

    const { data: esData, error: employeeShiftsError } = await supabase
      .from("employee_shifts")
      .select(`*, shifts!inner(start_time, end_time), is_active`);
    if (employeeShiftsError) throw employeeShiftsError;
    employeeShiftsData = esData;

    const { data: sData, error: shiftsError } = await supabase
      .from("shifts")
      .select(`id, start_time, end_time`);
    if (shiftsError) throw shiftsError;
    shiftsData = sData;

    const shiftsMap = new Map(shiftsData.map(s => [s.id, s.start_time]));

    attendanceData.value = data.map((a: any) => {
      const attendanceDate = new Date(a.date);
      const dayOfWeek = attendanceDate.getDay(); // 0 for Sunday, 1 for Monday, etc.

      const employeeShift = employeeShiftsData.find(
        (es: any) => es.employee_id === a.employee_id && es.day_of_week === dayOfWeek
      );

      const shiftStartTime = employeeShift ? shiftsMap.get(employeeShift.shift_id) : null;

      return {
        ...a,
        employee_name: a.profiles?.full_name || "N/A",
        profiles: undefined,
        total_lateness_minutes: calculateLateness(a.check_in, shiftStartTime, a.date),
      };
    }) as Attendance[];
  } catch (error: any) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
    calculateSummaryStats(employeeShiftsData, shiftsData);
  }
};

const calculateSummaryStats = (employeeShiftsData: any[], shiftsData: any[]) => {
  const stats: { [key: string]: { present: number; absent: number; late: number; sick: number; permission: number; total_days: number; total_lateness_minutes: number } } = {};

  // Initialize stats for all employees
  employees.value.forEach(emp => {
    stats[emp.id] = { present: 0, absent: 0, late: 0, sick: 0, permission: 0, total_days: 0, total_lateness_minutes: 0 };
  });

  // Create a map for active employee shifts for quick lookup
  const employeeScheduledDays = new Map<string, Set<number>>(); // employee_id -> Set of day_of_week
  employeeShiftsData.forEach(es => {
    if (es.is_active) {
      if (!employeeScheduledDays.has(es.employee_id)) {
        employeeScheduledDays.set(es.employee_id, new Set());
      }
      employeeScheduledDays.get(es.employee_id)?.add(es.day_of_week);
    }
  });

  // Calculate expected working days based on date range and employee shifts
  if (startDate.value && endDate.value) {
    let current = startDate.value.toDate(getLocalTimeZone());
    const end = endDate.value.toDate(getLocalTimeZone());

    // Loop through each day in the date range
    while (current <= end) {
      const dayOfWeek = current.getDay(); // 0 for Sunday, 1 for Monday, etc.
      employees.value.forEach(emp => {
        if (employeeScheduledDays.has(emp.id) && employeeScheduledDays.get(emp.id)?.has(dayOfWeek)) {
          stats[emp.id].total_days++; // Increment total_days for scheduled days
        }
      });
      current.setDate(current.getDate() + 1); // Move to next day
    }
  }

  // Populate other stats from attendance data
  attendanceData.value.forEach(record => {
    if (!stats[record.employee_id]) {
      // This case should ideally not happen if all employees are initialized, but good for safety
      stats[record.employee_id] = { present: 0, absent: 0, late: 0, sick: 0, permission: 0, total_days: 0, total_lateness_minutes: 0 };
    }

    if (record.status === 'present') {
      stats[record.employee_id].present++;
    } else if (record.status === 'absent') {
      stats[record.employee_id].absent++;
    } else if (record.status === 'late') {
      stats[record.employee_id].late++;
    } else if (record.status === 'sick') {
      stats[record.employee_id].sick++;
    } else if (record.status === 'permission') {
      stats[record.employee_id].permission++;
    } else if (record.status === 'half_day') {
      stats[record.employee_id].present++; // Half day counts as present for total days
    }
    stats[record.employee_id].total_lateness_minutes += record.total_lateness_minutes || 0;
  });
  summaryStats.value = stats;
};

const openPhotoUrl = (url: string | null) => {
  if (url && process.client) {
    window.open(url, '_blank');
  }
};

const calculateLateness = (checkInTime: string | null, shiftStartTime: string | null, attendanceDate: string): number | null => {
  if (!checkInTime || !shiftStartTime) {
    return null;
  }

  const checkInDate = new Date(checkInTime);
  const [shiftHour, shiftMinute, shiftSecond] = shiftStartTime.split(':').map(Number);

  const shiftStartDateTime = new Date(attendanceDate);
  shiftStartDateTime.setHours(shiftHour, shiftMinute, shiftSecond, 0);

  if (checkInDate > shiftStartDateTime) {
    const diffMs = checkInDate.getTime() - shiftStartDateTime.getTime();
    return Math.round(diffMs / (1000 * 60)); // Lateness in minutes
  }
  return 0; // Not late
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
    pageLoading.value = true;
    try {
        await checkUserRole();
        if (hasAdminOrManagerRole.value) {
            await fetchEmployees();
            await fetchAttendanceData(); // Initial load
        }
    } catch (error: any) {
        errorMessage.value = error.message;
    } finally {
        pageLoading.value = false;
    }

});

watch(
  [user, selectedEmployeeId, startDate, endDate, attendanceStatusFilter],
  async ([newUser]) => {
    if (newUser) {
      await checkUserRole();
      if (hasAdminOrManagerRole.value) {
        await fetchEmployees();
        selectedEmployeeName.value = selectedEmployeeId.value
          ? employees.value.find((e) => e.id === selectedEmployeeId.value)?.full_name || null
          : null;
        await fetchAttendanceData();
      }
    } else {
      hasAdminOrManagerRole.value = false;
      attendanceData.value = [];
      employees.value = [];
      selectedEmployeeName.value = null;
      summaryStats.value = {};
    }
  }
);
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
