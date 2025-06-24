<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-2 sm:p-4">
    <h1 class="text-2xl sm:text-3xl font-bold mb-4 sm:mb-6 text-gray-900 dark:text-white">
      Riwayat Transaksi
    </h1>

    <div v-if="pageLoading" class="flex justify-center items-center h-64">
      <div class="spinner"></div>
    </div>

    <div v-else-if="!hasAccessRole" class="text-center text-red-500 dark:text-red-400">
      Anda tidak memiliki izin untuk mengakses halaman ini.
    </div>

    <div v-else>
      <div class="mb-4 flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <Input
          v-model="searchQuery"
          placeholder="Cari nomor transaksi..."
          class="w-full sm:max-w-xs bg-white dark:bg-gray-950"
        />
        <div class="flex gap-2 w-full sm:w-auto">
          <Dialog :open="isFilterDialogOpen" @update:open="isFilterDialogOpen = $event">
            <DialogTrigger as-child>
              <Button variant="outline" class="w-full sm:w-auto">
                <Filter class="h-4 w-4 mr-2" />Filter
              </Button>
            </DialogTrigger>
            <DialogContent class="sm:max-w-[425px] p-6">
              <DialogHeader>
                <DialogTitle>Filter Transaksi</DialogTitle>
                <DialogDescription>Pilih opsi filter untuk transaksi.</DialogDescription>
              </DialogHeader>
              <div class="grid gap-4 py-4">
                <div>
                  <Label for="filterStatus" class="mb-2">Status Pembayaran</Label>
                  <Select v-model="filterStatus">
                    <SelectTrigger class="bg-white dark:bg-gray-950 w-full">
                      <SelectValue
                        :placeholder="filterStatus === 'all' ? 'Filter Status' : filterStatus"
                      />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">Semua Status</SelectItem>
                      <SelectItem value="completed">Selesai</SelectItem>
                      <SelectItem value="pending">Pending</SelectItem>
                      <SelectItem value="cancelled">Dibatalkan</SelectItem>
                      <SelectItem value="refunded">Dikembalikan</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div v-if="hasAdminOrManagerRole">
                  <Label for="filterCashier" class="mb-2">Kasir</Label>
                  <Select v-model="filterCashier">
                    <SelectTrigger class="bg-white dark:bg-gray-950 w-full">
                      <SelectValue
                        :placeholder="
                          filterCashier === 'all'
                            ? 'Filter Kasir'
                            : cashiers.find((c) => c.id === filterCashier)?.full_name ||
                              'Filter Kasir'
                        "
                      />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">Semua Kasir</SelectItem>
                      <SelectItem v-for="cashier in cashiers" :key="cashier.id" :value="cashier.id">
                        {{ cashier.full_name }}
                      </SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
              <DialogFooter>
                <Button type="button" variant="outline" @click="isFilterDialogOpen = false">Tutup</Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Daftar Transaksi</CardTitle>
        </CardHeader>
        <CardContent>
          <div class="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead class="min-w-[150px]">No. Transaksi</TableHead>
                  <TableHead class="min-w-[150px] hidden md:table-cell">Tanggal</TableHead>
                  <TableHead class="min-w-[100px] hidden md:table-cell">Kasir</TableHead>
                  <TableHead class="min-w-[100px] hidden md:table-cell">Pelanggan</TableHead>
                  <TableHead class="min-w-[100px]">Total Akhir</TableHead>
                  <TableHead class="min-w-[80px]">Status</TableHead>
                  <TableHead class="min-w-[150px]">Aksi</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                <TableRow v-for="transaction in transactions" :key="transaction.id" @click="showTransactionDetail(transaction)" class="cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700">
                  <TableCell>{{ transaction.transaction_number }}</TableCell>
                  <TableCell class="hidden md:table-cell">{{ formatDate(transaction.created_at) }}</TableCell>
                  <TableCell class="hidden md:table-cell">{{ transaction.cashier_name || "N/A" }}</TableCell>
                  <TableCell class="hidden md:table-cell">{{ transaction.customer_name || "Umum" }}</TableCell>
                  <TableCell>{{ formatCurrency(transaction.final_amount) }}</TableCell>
                  <TableCell>
                    <Badge :variant="getStatusVariant(transaction.payment_status)">
                      {{ transaction.payment_status }}
                    </Badge>
                  </TableCell>
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
                        <DropdownMenuItem @click="showTransactionDetail(transaction)">
                          <Info class="mr-2 h-4 w-4" />Detail
                        </DropdownMenuItem>
                        <DropdownMenuItem @click="editTransaction(transaction)">
                          <Edit class="mr-2 h-4 w-4" />Edit
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
                <TableRow v-if="transactions.length === 0 && !loading">
                  <TableCell colspan="7" class="text-center text-gray-500 dark:text-gray-400">
                    Tidak ada transaksi ditemukan.
                  </TableCell>
                </TableRow>
              </TableBody>
            </Table>
          </div>
          <div v-if="loading" class="text-center text-gray-500 dark:text-gray-400 mt-4">
            Memuat transaksi...
          </div>
          <Toaster />
        </CardContent>
      </Card>

      <!-- Edit Transaction Dialog -->
      <Dialog :open="isTransactionFormOpen" @update:open="isTransactionFormOpen = $event">
        <DialogContent class="sm:max-w-[600px] p-6 max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Edit Transaksi</DialogTitle>
            <DialogDescription>Perbarui detail transaksi.</DialogDescription>
          </DialogHeader>
          <form @submit.prevent="saveTransaction" class="space-y-4 py-4">
            <div>
              <Label for="transactionNumber" class="mb-2">No. Transaksi</Label>
              <Input
                id="transactionNumber"
                v-model="transactionForm.transaction_number"
                type="text"
                disabled
                class="bg-gray-100 dark:bg-gray-700"
              />
            </div>
            <div>
              <Label for="paymentStatus" class="mb-2">Status Pembayaran</Label>
              <Select v-model="transactionForm.payment_status">
                <SelectTrigger>
                  <SelectValue placeholder="Pilih Status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="completed">Selesai</SelectItem>
                  <SelectItem value="pending">Pending</SelectItem>
                  <SelectItem value="cancelled">Dibatalkan</SelectItem>
                  <SelectItem value="refunded">Dikembalikan</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label for="transactionNotes" class="mb-2">Catatan</Label>
              <Textarea
                id="transactionNotes"
                v-model="transactionForm.notes"
                placeholder="Catatan transaksi (opsional)"
              />
            </div>
            <DialogFooter class="flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2 pt-4">
              <DialogClose as-child>
                <Button type="button" variant="outline" @click="cancelEdit"
                  class="w-full sm:w-auto mb-2 sm:mb-0"
                  >Batal</Button
                >
              </DialogClose>
              <Button type="submit" :disabled="loading" class="w-full sm:w-auto">
                <span v-if="loading">Menyimpan...</span>
                <span v-else>Perbarui Transaksi</span>
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <!-- Transaction Detail Dialog -->
      <Dialog :open="isTransactionDetailOpen" @update:open="isTransactionDetailOpen = $event">
        <DialogContent class="sm:max-w-[600px] p-6 max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Detail Transaksi</DialogTitle>
            <DialogDescription>Informasi lengkap mengenai transaksi ini.</DialogDescription>
          </DialogHeader>
          <div v-if="selectedTransaction" class="grid gap-4 py-4">
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailTransactionNumber" class="text-right">No. Transaksi</Label>
              <Input id="detailTransactionNumber" :model-value="selectedTransaction.transaction_number" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailCreatedAt" class="text-right">Tanggal</Label>
              <Input id="detailCreatedAt" :model-value="formatDate(selectedTransaction.created_at)" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailCashier" class="text-right">Kasir</Label>
              <Input id="detailCashier" :model-value="selectedTransaction.cashier_name || 'N/A'" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailCustomer" class="text-right">Pelanggan</Label>
              <Input id="detailCustomer" :model-value="selectedTransaction.customer_name || 'Umum'" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailTotalAmount" class="text-right">Total Awal</Label>
              <Input id="detailTotalAmount" :model-value="formatCurrency(selectedTransaction.total_amount)" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailDiscountAmount" class="text-right">Diskon</Label>
              <Input id="detailDiscountAmount" :model-value="formatCurrency(selectedTransaction.discount_amount)" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailTaxAmount" class="text-right">Pajak</Label>
              <Input id="detailTaxAmount" :model-value="formatCurrency(selectedTransaction.tax_amount)" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailFinalAmount" class="text-right">Total Akhir</Label>
              <Input id="detailFinalAmount" :model-value="formatCurrency(selectedTransaction.final_amount)" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailPaymentMethod" class="text-right">Metode Pembayaran</Label>
              <Input id="detailPaymentMethod" :model-value="selectedTransaction.payment_method" readonly class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailPaymentStatus" class="text-right">Status Pembayaran</Label>
              <div class="col-span-3">
                <Badge :variant="getStatusVariant(selectedTransaction.payment_status)">
                  {{ selectedTransaction.payment_status }}
                </Badge>
              </div>
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <Label for="detailNotes" class="text-right">Catatan</Label>
              <Textarea id="detailNotes" :model-value="selectedTransaction.notes || 'Tidak ada catatan'" readonly class="col-span-3" />
            </div>

            <h4 class="font-semibold text-md text-gray-900 dark:text-white mt-4">
              Item Transaksi:
            </h4>
            <Table class="w-full">
              <TableHeader>
                <TableRow>
                  <TableHead>Produk</TableHead>
                  <TableHead>Qty</TableHead>
                  <TableHead>Harga Satuan</TableHead>
                  <TableHead>Total</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                <template v-if="selectedTransaction.items && selectedTransaction.items.length > 0">
                  <TableRow v-for="item in selectedTransaction.items" :key="item.id">
                    <TableCell>{{ item.product_name }}</TableCell>
                    <TableCell>{{ item.quantity }}</TableCell>
                    <TableCell>{{ formatCurrency(item.unit_price) }}</TableCell>
                    <TableCell>{{ formatCurrency(item.total_price) }}</TableCell>
                  </TableRow>
                </template>
                <TableRow v-else>
                  <TableCell colspan="4" class="text-center text-gray-500 dark:text-gray-400">
                    Tidak ada item transaksi.
                  </TableCell>
                </TableRow>
              </TableBody>
            </Table>
          </div>
          <DialogFooter>
            <DialogClose as-child>
              <Button type="button" variant="outline">Tutup</Button>
            </DialogClose>
            <Button @click="editTransaction(selectedTransaction!)">
              <Edit class="mr-2 h-4 w-4" />Edit Transaksi
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  title: 'Transactions - Aplikasi Kasir'
})
import { ref, onMounted, computed, watch } from "vue";
import { useSupabaseClient, useSupabaseUser } from "#imports";
import { toast } from 'vue-sonner';
import { Toaster } from '@/components/ui/sonner';
import 'vue-sonner/style.css' // vue-sonner v2 requires this import
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
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { MoreHorizontal, Edit, Trash2, Info, Filter } from "lucide-vue-next";

interface TransactionItem {
  id: string;
  transaction_id: string;
  product_id: string;
  product_name: string; // Joined from products table
  quantity: number;
  unit_price: number;
  total_price: number;
  created_at: string;
}

interface Transaction {
  id: string;
  transaction_number: string;
  cashier_id: string | null;
  cashier_name: string | null; // Joined from profiles table
  customer_id: string | null;
  customer_name: string | null; // Joined from customers table
  total_amount: number;
  discount_amount: number;
  tax_amount: number;
  final_amount: number;
  payment_method: string;
  payment_status: "pending" | "completed" | "cancelled" | "refunded";
  notes: string | null;
  created_at: string;
  updated_at: string;
  items?: TransactionItem[]; // To store joined items
}

interface CashierProfile {
  id: string;
  full_name: string;
}

const supabase = useSupabaseClient();
const user = useSupabaseUser();

const pageLoading = ref(true);
const transactions = ref<Transaction[]>([]);
const cashiers = ref<CashierProfile[]>([]);
const loading = ref(false);
const hasAccessRole = ref(false);
const hasAdminOrManagerRole = ref(false);

const searchQuery = ref("");
const filterStatus = ref("all");
const filterCashier = ref("all");
const isTransactionFormOpen = ref(false);
const isFilterDialogOpen = ref(false); // New ref for filter dialog
const isTransactionDetailOpen = ref(false); // New ref for transaction detail dialog
const selectedTransaction = ref<Transaction | null>(null); // Stores the selected transaction for detail view
const isEditing = ref(false); // New ref for edit mode

const transactionForm = ref<Transaction>({
  id: "",
  transaction_number: "",
  cashier_id: null,
  cashier_name: null,
  customer_id: null,
  customer_name: null,
  total_amount: 0,
  discount_amount: 0,
  tax_amount: 0,
  final_amount: 0,
  payment_method: "",
  payment_status: "pending",
  notes: null,
  created_at: "",
  updated_at: "",
  items: [],
});

const fetchTransactions = async () => {
  loading.value = true;
  try {
    let query = supabase
      .from("transactions")
      .select(
        `
        *,
        profiles!transactions_cashier_id_fkey(full_name),
        customers!transactions_customer_id_fkey(name)
      `
      )
      .order("created_at", { ascending: false });

    if (!hasAdminOrManagerRole.value && user.value) {
      // If not admin/manager, only fetch their own transactions
      query = query.eq("cashier_id", user.value.id);
    } else if (filterCashier.value !== "all") {
      // If admin/manager and a specific cashier is selected
      query = query.eq("cashier_id", filterCashier.value);
    }

    if (filterStatus.value !== "all") {
      query = query.eq("payment_status", filterStatus.value);
    }

    if (searchQuery.value) {
      query = query.ilike("transaction_number", `%${searchQuery.value}%`);
    }

    const { data, error } = await query;

    if (error) throw error;

    transactions.value = data.map((t: any) => ({
      ...t,
      cashier_name: t.profiles?.full_name || "N/A",
      customer_name: t.customers?.name || "Umum",
      profiles: undefined, // Remove nested profiles object
      customers: undefined, // Remove nested customers object
    })) as Transaction[];
  } catch (error: any) {
    toast.error("Gagal memuat transaksi!", {
      description: error.message,
    });
  } finally {
    loading.value = false;
  }
};

const fetchCashiers = async () => {
  if (!hasAdminOrManagerRole.value) return;
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
  hasAdminOrManagerRole.value = data.role === "admin" || data.role === "manager";

  if (!hasAccessRole.value) {
    toast.warning("Anda tidak memiliki izin untuk mengakses halaman ini.", {
      description: "Silakan hubungi administrator untuk mendapatkan akses.",
    });
  }
};

const editTransaction = (transaction: Transaction) => {
  isEditing.value = true;
  transactionForm.value = { ...transaction };
  isTransactionFormOpen.value = true; // Open the dialog for editing
  isTransactionDetailOpen.value = false; // Close detail dialog if open
};

const cancelEdit = () => {
  resetForm();
  isTransactionFormOpen.value = false;
};

const saveTransaction = async () => {
  loading.value = true;

  try {
    const { error } = await supabase
      .from("transactions")
      .update({
        payment_status: transactionForm.value.payment_status,
        notes: transactionForm.value.notes,
        updated_at: new Date().toISOString(),
      })
      .eq("id", transactionForm.value.id);

    if (error) throw error;
    toast.success("Transaksi berhasil diperbarui!", {
      description: `Transaksi ${transactionForm.value.transaction_number} telah berhasil diperbarui.`,
    });
    resetForm();
    await fetchTransactions();
    isTransactionFormOpen.value = false;
  } catch (error: any) {
    toast.error("Gagal memperbarui transaksi!", {
      description: error.message,
    });
  } finally {
    loading.value = false;
  }
};

const resetForm = () => {
  isEditing.value = false; // Reset isEditing when form is reset
  transactionForm.value = {
    id: "",
    transaction_number: "",
    cashier_id: null,
    cashier_name: null,
    customer_id: null,
    customer_name: null,
    total_amount: 0,
    discount_amount: 0,
    tax_amount: 0,
    final_amount: 0,
    payment_method: "",
    payment_status: "pending",
    notes: null,
    created_at: "",
    updated_at: "",
    items: [],
  };
};

const showTransactionDetail = async (transaction: Transaction) => {
  selectedTransaction.value = { ...transaction }; // Copy to avoid direct mutation
  isTransactionDetailOpen.value = true;

  // Fetch transaction items if not already fetched
  if (!selectedTransaction.value.items || selectedTransaction.value.items.length === 0) {
    loading.value = true;
    try {
      const { data, error } = await supabase
        .from("transaction_items")
        .select(
          `
          *,
          products!transaction_items_product_id_fkey(name)
        `
        )
        .eq("transaction_id", transaction.id)
        .order("created_at", { ascending: true });

      if (error) throw error;

      const items = data.map((item: any) => ({
        ...item,
        product_name: item.products?.name || "Produk Tidak Ditemukan",
        products: undefined,
      })) as TransactionItem[];

      if (selectedTransaction.value) {
        selectedTransaction.value.items = items;
      }
    } catch (error: any) {
      toast.error("Gagal memuat detail item transaksi!", {
        description: error.message,
      });
    } finally {
      loading.value = false;
    }
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
    if (hasAccessRole.value) {
      await fetchCashiers(); // Fetch cashiers only if admin/manager
      await fetchTransactions();
    }
  } catch (error: any) {
    toast.error("Terjadi kesalahan saat memuat data awal!", {
      description: error.message,
    });
  } finally {
    pageLoading.value = false;
  }
});

watch([user, filterStatus, filterCashier, searchQuery], async ([newUser]) => {
  if (newUser) {
    await checkUserRole();
    if (hasAccessRole.value) {
      await fetchCashiers();
      await fetchTransactions();
    }
  } else {
    hasAccessRole.value = false;
    hasAdminOrManagerRole.value = false;
    transactions.value = [];
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
