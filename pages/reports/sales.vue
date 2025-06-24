<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-4">
    <h1 class="text-3xl font-bold mb-6 text-gray-900 dark:text-white">
      Laporan Penjualan
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
              <Label for="reportType" class="mb-2">Tipe Laporan</Label>
              <Select v-model="reportType">
                <SelectTrigger id="reportType" class="bg-white dark:bg-gray-950 w-full">
                  <SelectValue :placeholder="reportType" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="daily">Harian</SelectItem>
                  <SelectItem value="weekly">Mingguan</SelectItem>
                  <SelectItem value="monthly">Bulanan</SelectItem>
                  <SelectItem value="custom">Kustom</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div v-if="reportType === 'custom'">
              <Label for="startDate" class="mb-2">Tanggal Mulai</Label>
              <Popover>
                <PopoverTrigger as-child class="hover:bg-white">
                  <Button
                    variant="outline"
                    :class="
                      cn(
                        'w-full justify-start text-left font-normal',
                        !startDateValue && 'text-muted-foreground'
                      )
                    "
                  >
                    <CalendarIcon class="mr-2 h-4 w-4" />
                    {{
                      startDateValue
                        ? df.format(startDateValue.toDate(getLocalTimeZone()))
                        : "Pilih tanggal"
                    }}
                  </Button>
                </PopoverTrigger>
                <PopoverContent class="w-auto p-0">
                  <Calendar v-model="startDateValue" initial-focus />
                </PopoverContent>
              </Popover>
            </div>
            <div v-if="reportType === 'custom'">
              <Label for="endDate" class="mb-2">Tanggal Akhir</Label>
              <Popover>
                <PopoverTrigger as-child class="hover:bg-white">
                  <Button
                    variant="outline"
                    :class="
                      cn(
                        'w-full justify-start text-left font-normal',
                        !endDateValue && 'text-muted-foreground'
                      )
                    "
                  >
                    <CalendarIcon class="mr-2 h-4 w-4" />
                    {{
                      endDateValue
                        ? df.format(endDateValue.toDate(getLocalTimeZone()))
                        : "Pilih tanggal"
                    }}
                  </Button>
                </PopoverTrigger>
                <PopoverContent class="w-auto p-0">
                  <Calendar v-model="endDateValue" initial-focus />
                </PopoverContent>
              </Popover>
            </div>
            <div>
              <Label for="cashierFilter" class="mb-2">Filter Kasir</Label>
              <Select v-model="selectedCashierId">
                <SelectTrigger id="cashierFilter" class="bg-white dark:bg-gray-950 w-full">
                  <SelectValue
                    :placeholder="
                      selectedCashierId
                        ? cashiers.find((c) => c.id === selectedCashierId)?.full_name
                        : 'Semua Kasir'
                    "
                  />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Semua Kasir</SelectItem>
                  <SelectItem
                    v-for="cashier in cashiers"
                    :key="cashier.id"
                    :value="cashier.id"
                  >
                    {{ cashier.full_name }}
                  </SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardContent>
      </Card>
      <div v-if="errorMessage" class="text-red-500 text-sm mb-4">
        {{ errorMessage }}
      </div>

      <!-- Sales Summary -->
      <Card class="mb-6">
        <CardHeader>
          <CardTitle>Ringkasan Penjualan</CardTitle>
        </CardHeader>
        <CardContent>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="border dark:border-gray-700 rounded-lg p-4">
              <p class="text-gray-600 dark:text-gray-400">Total Penjualan Bruto</p>
              <p class="text-xl font-bold text-green-600 dark:text-green-400">
                {{ formatCurrency(salesSummary.totalGrossSales) }}
              </p>
            </div>
            <div class="border dark:border-gray-700 rounded-lg p-4">
              <p class="text-gray-600 dark:text-gray-400">Total Diskon</p>
              <p class="text-xl font-bold text-red-600 dark:text-red-400">
                {{ formatCurrency(salesSummary.totalDiscount) }}
              </p>
            </div>
            <div class="border dark:border-gray-700 rounded-lg p-4">
              <p class="text-gray-600 dark:text-gray-400">Total Pajak</p>
              <p class="text-xl font-bold text-blue-600 dark:text-blue-400">
                {{ formatCurrency(salesSummary.totalTax) }}
              </p>
            </div>
            <div class="border dark:border-gray-700 rounded-lg p-4">
              <p class="text-gray-600 dark:text-gray-400">Total Penjualan Bersih</p>
              <p class="text-xl font-bold text-green-600 dark:text-green-400">
                {{ formatCurrency(salesSummary.totalNetSales) }}
              </p>
            </div>
            <div class="border dark:border-gray-700 rounded-lg p-4">
              <p class="text-gray-600 dark:text-gray-400">Jumlah Transaksi</p>
              <p class="text-xl font-bold text-gray-900 dark:text-white">
                {{ salesSummary.transactionCount }}
              </p>
            </div>
            <div class="border dark:border-gray-700 rounded-lg p-4">
              <p class="text-gray-600 dark:text-gray-400">Rata-rata Transaksi</p>
              <p class="text-xl font-bold text-gray-900 dark:text-white">
                {{ formatCurrency(salesSummary.averageTransaction) }}
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      <!-- Sales Chart -->
      <Card v-if="salesChartData.labels.length > 0" class="mb-6">
        <CardHeader>
          <CardTitle>Grafik Penjualan</CardTitle>
        </CardHeader>
        <CardContent>
          <div class="h-80">
            <BarChart :chart-data="salesChartData" />
          </div>
        </CardContent>
      </Card>

      <!-- Sales Details Table -->
      <Card>
        <CardHeader>
          <CardTitle>Detail Penjualan</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>No. Transaksi</TableHead>
                <TableHead>Tanggal</TableHead>
                <TableHead>Kasir</TableHead>
                <TableHead>Pelanggan</TableHead>
                <TableHead>Total Akhir</TableHead>
                <TableHead>Status</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              <TableRow v-for="transaction in salesData" :key="transaction.id">
                <TableCell>{{ transaction.transaction_number }}</TableCell>
                <TableCell>{{ formatDate(transaction.created_at) }}</TableCell>
                <TableCell>{{ transaction.cashier_name || "N/A" }}</TableCell>
                <TableCell>{{ transaction.customer_name || "Umum" }}</TableCell>
                <TableCell>{{ formatCurrency(transaction.final_amount) }}</TableCell>
                <TableCell>
                  <Badge :variant="getStatusVariant(transaction.payment_status)">
                    {{ transaction.payment_status }}
                  </Badge>
                </TableCell>
              </TableRow>
              <TableRow v-if="salesData.length === 0 && !loading">
                <TableCell colspan="6" class="text-center text-gray-500 dark:text-gray-400">
                  Tidak ada data penjualan untuk periode ini.
                </TableCell>
              </TableRow>
            </TableBody>
          </Table>
          <div v-if="loading" class="text-center text-gray-500 dark:text-gray-400 mt-4">
            Memuat data penjualan...
          </div>
        </CardContent>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch, computed } from "vue";
import { useSupabaseClient, useSupabaseUser } from "#imports";
import {
  DateFormatter,
  type DateValue,
  getLocalTimeZone,
} from '@internationalized/date'
import { CalendarIcon } from 'lucide-vue-next'
import { cn } from '@/lib/utils'
import { Button } from "@/components/ui/button";
import { Calendar } from '@/components/ui/calendar'
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
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
import BarChart from "@/components/ui/chart/BarChart.vue";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

interface Transaction {
  id: string;
  transaction_number: string;
  cashier_id: string | null;
  cashier_name: string | null;
  customer_id: string | null;
  customer_name: string | null;
  total_amount: number;
  discount_amount: number;
  tax_amount: number;
  final_amount: number;
  payment_status: "pending" | "completed" | "cancelled" | "refunded";
  created_at: string;
}

interface SalesSummary {
  totalGrossSales: number;
  totalDiscount: number;
  totalTax: number;
  totalNetSales: number;
  transactionCount: number;
  averageTransaction: number;
}

interface CashierProfile {
  id: string;
  full_name: string;
}

const supabase = useSupabaseClient();
const user = useSupabaseUser();

const df = new DateFormatter('en-US', {
  dateStyle: 'long',
})
const pageLoading = ref(true);
const reportType = ref("daily");
const startDateValue = ref<DateValue>();
const endDateValue = ref<DateValue>();
const selectedCashierId = ref("");

const salesData = ref<Transaction[]>([]);
const salesSummary = ref<SalesSummary>({
  totalGrossSales: 0,
  totalDiscount: 0,
  totalTax: 0,
  totalNetSales: 0,
  transactionCount: 0,
  averageTransaction: 0,
});
const cashiers = ref<CashierProfile[]>([]);

const salesChartData = computed(() => {
  const labels: string[] = [];
  const data: number[] = [];

  // Group sales data by date for the chart
  const salesByDate: { [key: string]: number } = {};
  salesData.value.forEach((transaction) => {
    const date = new Date(transaction.created_at).toLocaleDateString("id-ID", {
      day: "2-digit",
      month: "short",
      year: "numeric",
    });
    salesByDate[date] = (salesByDate[date] || 0) + transaction.final_amount;
  });

  // Sort dates and populate labels and data
  Object.keys(salesByDate)
    .sort((a, b) => new Date(a).getTime() - new Date(b).getTime())
    .forEach((date) => {
      labels.push(date);
      data.push(salesByDate[date]);
    });

  return {
    labels: labels,
    datasets: [
      {
        label: "Total Penjualan Bersih",
        backgroundColor: "#4CAF50", // Green color for sales
        data: data,
      },
    ],
  };
});

const loading = ref(false);
const errorMessage = ref("");
const hasAdminOrManagerRole = ref(false);

const fetchSalesData = async () => {
  loading.value = true;
  errorMessage.value = "";
  try {
    let start: Date;
    let end: Date;

    const today = new Date();
    today.setHours(0, 0, 0, 0); // Start of today

    switch (reportType.value) {
      case "daily":
        start = today;
        end = new Date(today);
        end.setDate(today.getDate() + 1); // End of today
        break;
      case "weekly":
        start = new Date(today);
        start.setDate(today.getDate() - today.getDay()); // Start of current week (Sunday)
        end = new Date(start);
        end.setDate(start.getDate() + 7); // End of current week
        break;
      case "monthly":
        start = new Date(today.getFullYear(), today.getMonth(), 1); // Start of current month
        end = new Date(today.getFullYear(), today.getMonth() + 1, 1); // Start of next month
        break;
      case "custom":
        if (!startDateValue.value || !endDateValue.value) {
          errorMessage.value =
            "Tanggal mulai dan tanggal akhir harus diisi untuk laporan kustom.";
          loading.value = false;
          return;
        }
        start = startDateValue.value.toDate(getLocalTimeZone());
        end = endDateValue.value.toDate(getLocalTimeZone());
        end.setDate(end.getDate() + 1); // Include the end date fully
        break;
      default:
        start = today;
        end = new Date(today);
        end.setDate(today.getDate() + 1);
        break;
    }

    let query = supabase
      .from("transactions")
      .select(
        `
        *,
        profiles!transactions_cashier_id_fkey(full_name),
        customers!transactions_customer_id_fkey(name)
      `
      )
      .gte("created_at", start.toISOString())
      .lt("created_at", end.toISOString())
      .order("created_at", { ascending: false });

    if (selectedCashierId.value) {
      query = query.eq("cashier_id", selectedCashierId.value);
    }

    const { data, error } = await query;

    if (error) throw error;

    salesData.value = data.map((t: any) => ({
      ...t,
      cashier_name: t.profiles?.full_name || "N/A",
      customer_name: t.customers?.name || "Umum",
      profiles: undefined,
      customers: undefined,
    })) as Transaction[];

    calculateSummary();
  } catch (error: any) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
};

const calculateSummary = () => {
  let totalGross = 0;
  let totalDisc = 0;
  let totalTax = 0;
  let totalNet = 0;
  let count = 0;

  salesData.value.forEach((t) => {
    totalGross += t.total_amount;
    totalDisc += t.discount_amount;
    totalTax += t.tax_amount;
    totalNet += t.final_amount;
    count++;
  });

  salesSummary.value = {
    totalGrossSales: totalGross,
    totalDiscount: totalDisc,
    totalTax: totalTax,
    totalNetSales: totalNet,
    transactionCount: count,
    averageTransaction: count > 0 ? totalNet / count : 0,
  };
};

const fetchCashiers = async () => {
  try {
    const { data, error } = await supabase
      .from("profiles")
      .select("id, full_name")
      .in("role", ["admin", "manager", "cashier"])
      .order("full_name", { ascending: true });

    if (error) throw error;
    cashiers.value = data as CashierProfile[];
  } catch (error: any) {
    console.error("Error fetching cashiers:", error.message);
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
    hour: "2-digit",
    minute: "2-digit",
  };
  return new Date(dateString).toLocaleDateString("id-ID", options);
};

const formatCurrency = (value: number) => {
  return new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(value);
};

const getStatusVariant = (status: "pending" | "completed" | "cancelled" | "refunded") => {
  switch (status) {
    case "completed":
      return "default";
    case "pending":
      return "secondary";
    case "cancelled":
      return "destructive";
    case "refunded":
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
    await fetchCashiers();
    await fetchSalesData(); // Initial load
  }
    } catch (error: any) {
      errorMessage.value = error.message;
    } finally {
      pageLoading.value = false;
    }
});

watch([user, reportType, startDateValue, endDateValue, selectedCashierId], async ([newUser]) => {
  if (newUser) {
    await checkUserRole();
    if (hasAdminOrManagerRole.value) {
      await fetchCashiers();
      await fetchSalesData(); // Re-fetch data when filters change
    }
  } else {
    hasAdminOrManagerRole.value = false;
    salesData.value = [];
    salesSummary.value = {
      totalGrossSales: 0,
      totalDiscount: 0,
      totalTax: 0,
      totalNetSales: 0,
      transactionCount: 0,
      averageTransaction: 0,
    };
    cashiers.value = [];
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
