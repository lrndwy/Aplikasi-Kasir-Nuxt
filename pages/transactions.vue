<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-4">
    <h1 class="text-3xl font-bold mb-6 text-gray-900 dark:text-white">
      Riwayat Transaksi
    </h1>

    <div v-if="pageLoading" class="flex justify-center items-center h-64">
      <div class="spinner"></div>
    </div>

    <div v-else-if="!hasAccessRole" class="text-center text-red-500 dark:text-red-400">
      Anda tidak memiliki izin untuk mengakses halaman ini.
    </div>

    <div v-else>
      <div class="mb-4 flex space-x-4">
        <Input
          v-model="searchQuery"
          placeholder="Cari nomor transaksi..."
          class="w-full md:w-1/3 bg-white dark:bg-gray-950"
        />
        <Select v-model="filterStatus" class="w-full md:w-1/4">
          <SelectTrigger class="bg-white dark:bg-gray-950">
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
        <Select
          v-if="hasAdminOrManagerRole"
          v-model="filterCashier"
          class="w-full md:w-1/4"
        >
          <SelectTrigger class="bg-white dark:bg-gray-950">
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

      <div class="bg-white dark:bg-gray-800 shadow-md rounded-lg p-6">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>No. Transaksi</TableHead>
              <TableHead>Tanggal</TableHead>
              <TableHead>Kasir</TableHead>
              <TableHead>Pelanggan</TableHead>
              <TableHead>Total Akhir</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Aksi</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            <template v-if="transactions.length > 0">
              <template v-for="transaction in transactions" :key="transaction.id">
                <TableRow>
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
                  <TableCell>
                    <Button
                      variant="outline"
                      size="sm"
                      @click="viewTransactionDetails(transaction)"
                      >Detail</Button
                    >
                    <Button
                      variant="outline"
                      size="sm"
                      @click="editTransaction(transaction)"
                      class="ml-2"
                      >Edit</Button
                    >
                    <Button
                      variant="destructive"
                      size="sm"
                      @click="confirmDeleteTransaction(transaction.id)"
                      class="ml-2"
                      >Hapus</Button
                    >
                  </TableCell>
                </TableRow>
                <TableRow v-if="expandedTransactionId === transaction.id">
                  <TableCell colspan="7" class="p-4 bg-gray-50 dark:bg-gray-700">
                    <div class="space-y-2">
                      <h3 class="font-semibold text-lg text-gray-900 dark:text-white">
                        Detail Transaksi #{{ transaction.transaction_number }}
                      </h3>
                      <p class="text-sm text-gray-700 dark:text-gray-300">
                        <strong>Metode Pembayaran:</strong>
                        {{ transaction.payment_method }}
                      </p>
                      <p class="text-sm text-gray-700 dark:text-gray-300">
                        <strong>Diskon:</strong>
                        {{ formatCurrency(transaction.discount_amount) }}
                      </p>
                      <p class="text-sm text-gray-700 dark:text-gray-300">
                        <strong>Pajak:</strong>
                        {{ formatCurrency(transaction.tax_amount) }}
                      </p>
                      <p
                        v-if="transaction.notes"
                        class="text-sm text-gray-700 dark:text-gray-300"
                      >
                        <strong>Catatan:</strong> {{ transaction.notes }}
                      </p>

                      <h4
                        class="font-semibold text-md text-gray-900 dark:text-white mt-4"
                      >
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
                          <TableRow v-for="item in transaction.items" :key="item.id">
                            <TableCell>{{ item.product_name }}</TableCell>
                            <TableCell>{{ item.quantity }}</TableCell>
                            <TableCell>{{ formatCurrency(item.unit_price) }}</TableCell>
                            <TableCell>{{ formatCurrency(item.total_price) }}</TableCell>
                          </TableRow>
                        </TableBody>
                      </Table>
                    </div>
                  </TableCell>
                </TableRow>
              </template>
            </template>
            <TableRow v-else>
              <TableCell colspan="7" class="text-center text-gray-500 dark:text-gray-400">
                Tidak ada transaksi ditemukan.
              </TableCell>
            </TableRow>
          </TableBody>
        </Table>
        <div v-if="loading" class="text-center text-gray-500 dark:text-gray-400 mt-4">
          Memuat transaksi...
        </div>
        <div v-if="errorMessage" class="text-red-500 text-sm mt-4">
          {{ errorMessage }}
        </div>
        <div v-if="successMessage" class="text-green-500 text-sm mt-4">
          {{ successMessage }}
        </div>
      </div>

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
            <DialogFooter>
              <Button type="submit" :disabled="loading">
                <span v-if="loading">Menyimpan...</span>
                <span v-else>Perbarui Transaksi</span>
              </Button>
              <DialogClose as-child>
                <Button type="button" variant="outline" @click="cancelEdit">Batal</Button>
              </DialogClose>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <!-- Delete Confirmation Dialog -->
      <Dialog :open="isConfirmDeleteOpen" @update:open="isConfirmDeleteOpen = $event">
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Konfirmasi Hapus Transaksi</DialogTitle>
            <DialogDescription>
              Apakah Anda yakin ingin menghapus transaksi ini? Tindakan ini tidak dapat
              dibatalkan.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" @click="isConfirmDeleteOpen = false">Batal</Button>
            <Button
              variant="destructive"
              @click="deleteTransactionConfirmed"
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
  title: 'Transactions - Aplikasi Kasir'
})
import { ref, onMounted, computed, watch } from "vue";
import { useSupabaseClient, useSupabaseUser } from "#imports";
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
const errorMessage = ref("");
const hasAccessRole = ref(false);
const hasAdminOrManagerRole = ref(false);

const searchQuery = ref("");
const filterStatus = ref("all");
const filterCashier = ref("all");
const expandedTransactionId = ref<string | null>(null);
const isTransactionFormOpen = ref(false);
const isConfirmDeleteOpen = ref(false);
const transactionToDeleteId = ref<string | null>(null);
const successMessage = ref("");

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
  errorMessage.value = "";
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
    errorMessage.value = error.message;
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
    errorMessage.value = "Anda tidak memiliki izin untuk mengakses halaman ini.";
  }
};

const editTransaction = (transaction: Transaction) => {
  transactionForm.value = { ...transaction };
  errorMessage.value = "";
  successMessage.value = "";
  isTransactionFormOpen.value = true;
};

const cancelEdit = () => {
  resetForm();
  isTransactionFormOpen.value = false;
};

const saveTransaction = async () => {
  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";

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
    successMessage.value = "Transaksi berhasil diperbarui!";
    resetForm();
    await fetchTransactions();
    isTransactionFormOpen.value = false;
  } catch (error: any) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
};

const confirmDeleteTransaction = (id: string) => {
  transactionToDeleteId.value = id;
  isConfirmDeleteOpen.value = true;
};

const deleteTransactionConfirmed = async () => {
  if (!transactionToDeleteId.value) return;

  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";
  try {
    const { error } = await supabase
      .from("transactions")
      .delete()
      .eq("id", transactionToDeleteId.value);
    if (error) throw error;
    successMessage.value = "Transaksi berhasil dihapus!";
    await fetchTransactions();
    isConfirmDeleteOpen.value = false;
    transactionToDeleteId.value = null;
  } catch (error: any) {
    errorMessage.value = error.message;
  } finally {
    loading.value = false;
  }
};

const resetForm = () => {
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

const viewTransactionDetails = async (transaction: Transaction) => {
  if (expandedTransactionId.value === transaction.id) {
    expandedTransactionId.value = null; // Collapse if already expanded
    return;
  }

  loading.value = true;
  errorMessage.value = "";
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

    // Find the transaction in the main array and update its items
    const index = transactions.value.findIndex((t) => t.id === transaction.id);
    if (index !== -1) {
      transactions.value[index].items = items;
    }
    expandedTransactionId.value = transaction.id;
  } catch (error: any) {
    errorMessage.value = "Gagal memuat detail item: " + error.message;
  } finally {
    loading.value = false;
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
  } catch (error) {
    console.error("Error during initial data fetch:", error);
    errorMessage.value = "Gagal memuat data. Silakan coba lagi.";
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
