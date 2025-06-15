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
      <div class="flex gap-4 mb-6">
        <div>
          <Label for="employeeFilter" class="mb-2">Filter Karyawan</Label>
          <Select v-model="selectedEmployeeId">
            <SelectTrigger id="employeeFilter" class="bg-white dark:bg-gray-950">
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
            <PopoverTrigger as-child>
              <Button
                variant="outline"
                :class="
                  cn(
                    'w-[280px] justify-start text-left font-normal',
                    !startDate && 'text-muted-foreground'
                  )
                "
              >
                <CalendarIcon class="mr-2 h-4 w-4" />
                {{
                  startDate
                    ? df.format(startDate.toDate(getLocalTimeZone()))
                    : "Pick a date"
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
            <PopoverTrigger as-child>
              <Button
                variant="outline"
                :class="
                  cn(
                    'w-[280px] justify-start text-left font-normal',
                    !endDate && 'text-muted-foreground'
                  )
                "
              >
                <CalendarIcon class="mr-2 h-4 w-4" />
                {{
                  endDate ? df.format(endDate.toDate(getLocalTimeZone())) : "Pick a date"
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
            <SelectTrigger id="statusFilter" class="bg-white dark:bg-gray-950">
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
      <div v-if="errorMessage" class="text-red-500 text-sm mb-4">
        {{ errorMessage }}
      </div>

      <!-- Attendance Details Table -->
      <div class="bg-white dark:bg-gray-800 shadow-md rounded-lg p-6">
        <h2 class="text-2xl font-semibold mb-4 text-gray-900 dark:text-white">
          Detail Absensi
        </h2>
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
            </TableRow>
          </TableHeader>
          <TableBody>
            <TableRow v-for="record in attendanceData" :key="record.id">
              <TableCell>{{ record.employee_name }}</TableCell>
              <TableCell>{{ formatDate(record.date) }}</TableCell>
              <TableCell>{{
                record.check_in ? formatTime(record.check_in) : "-"
              }}</TableCell>
              <TableCell>{{
                record.check_out ? formatTime(record.check_out) : "-"
              }}</TableCell>
              <TableCell>{{ record.total_hours || "-" }}</TableCell>
              <TableCell>
                <Badge :variant="getStatusVariant(record.status)">
                  {{ record.status }}
                </Badge>
              </TableCell>
              <TableCell>{{ record.notes || "-" }}</TableCell>
            </TableRow>
            <TableRow v-if="attendanceData.length === 0 && !loading">
              <TableCell colspan="7" class="text-center text-gray-500 dark:text-gray-400">
                Tidak ada data absensi untuk kriteria ini.
              </TableCell>
            </TableRow>
          </TableBody>
        </Table>
        <div v-if="loading" class="text-center text-gray-500 dark:text-gray-400 mt-4">
          Memuat data absensi...
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import {
  DateFormatter,
  type DateValue,
  getLocalTimeZone,
} from '@internationalized/date'
import { CalendarIcon } from 'lucide-vue-next'

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

interface Attendance {
  id: string;
  employee_id: string;
  employee_name?: string;
  date: string;
  check_in: string | null;
  check_out: string | null;
  total_hours: number | null;
  status: "present" | "absent" | "late" | "half_day" | "sick" | "permission";
  notes: string | null;
  created_at: string;
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

const loading = ref(false);
const errorMessage = ref("");
const hasAdminOrManagerRole = ref(false);

const fetchAttendanceData = async () => {
  loading.value = true;
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

    attendanceData.value = data.map((a: any) => ({
      ...a,
      employee_name: a.profiles?.full_name || "N/A",
      profiles: undefined,
    })) as Attendance[];
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
        await fetchAttendanceData(); // Re-fetch data when filters change
      }
    } else {
      hasAdminOrManagerRole.value = false;
      attendanceData.value = [];
      employees.value = [];
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
