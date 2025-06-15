<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-4">
    <h1 class="text-3xl font-bold mb-6 text-gray-900 dark:text-white">Aplikasi Kasir</h1>

    <div v-if="pageLoading" class="flex justify-center items-center h-64">
      <div class="spinner"></div>
    </div>

    <div
      v-else-if="!hasCashierOrAdminRole"
      class="text-center text-red-500 dark:text-red-400"
    >
      Anda tidak memiliki izin untuk mengakses halaman ini.
    </div>

    <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Product Selection & Cart -->
      <div class="lg:col-span-2 bg-white dark:bg-gray-800 shadow-md rounded-lg p-6">
        <h2 class="text-2xl font-semibold mb-4 text-gray-900 dark:text-white">
          Pilih Produk
        </h2>

        <div class="mb-4">
          <Input v-model="searchQuery" placeholder="Cari produk..." class="w-full" />
        </div>

        <div
          class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 max-h-[400px] overflow-y-auto pr-2"
        >
          <div
            v-for="product in filteredProducts"
            :key="product.id"
            class="border dark:border-gray-700 rounded-lg p-4 cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
            @click="addProductToCart(product)"
          >
            <img
              :src="product.image_url || '/placeholder.jpg'"
              alt="Product Image"
              class="w-full h-32 object-cover rounded-md mb-2"
            />
            <h3 class="font-semibold text-lg text-gray-900 dark:text-white">
              {{ product.name }}
            </h3>
            <p class="text-sm text-gray-600 dark:text-gray-400">
              {{ product.description }}
            </p>
            <p class="text-md font-bold text-green-600 dark:text-green-400">
              {{ formatCurrency(product.price) }}
            </p>
            <p class="text-xs text-gray-500 dark:text-gray-400">
              Stok: {{ product.stock }}
            </p>
          </div>
          <div
            v-if="filteredProducts.length === 0 && !loadingProducts"
            class="col-span-full text-center text-gray-500 dark:text-gray-400"
          >
            Tidak ada produk ditemukan.
          </div>
          <div
            v-if="loadingProducts"
            class="col-span-full text-center text-gray-500 dark:text-gray-400"
          >
            Memuat produk...
          </div>
        </div>

        <h2 class="text-2xl font-semibold mt-6 mb-4 text-gray-900 dark:text-white">
          Keranjang Belanja
        </h2>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Produk</TableHead>
              <TableHead class="w-[100px]">Qty</TableHead>
              <TableHead>Harga Satuan</TableHead>
              <TableHead>Total</TableHead>
              <TableHead>Aksi</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            <TableRow v-for="(item, index) in cartItems" :key="item.product.id">
              <TableCell>{{ item.product.name }}</TableCell>
              <TableCell>
                <Input
                  type="number"
                  v-model.number="item.quantity"
                  min="1"
                  :max="item.product.stock"
                  @change="updateCartItemQuantity(index, $event.target.value)"
                  class="w-20"
                />
              </TableCell>
              <TableCell>{{ formatCurrency(item.product.price) }}</TableCell>
              <TableCell>{{ formatCurrency(item.total_price) }}</TableCell>
              <TableCell>
                <Button
                  variant="destructive"
                  size="sm"
                  @click="removeProductFromCart(index)"
                  >Hapus</Button
                >
              </TableCell>
            </TableRow>
            <TableRow v-if="cartItems.length === 0">
              <TableCell colspan="5" class="text-center text-gray-500 dark:text-gray-400">
                Keranjang kosong.
              </TableCell>
            </TableRow>
          </TableBody>
        </Table>
      </div>

      <!-- Transaction Summary & Payment -->
      <div
        class="lg:col-span-1 bg-white dark:bg-gray-800 shadow-md rounded-lg p-6 space-y-4"
      >
        <h2 class="text-2xl font-semibold mb-4 text-gray-900 dark:text-white">
          Ringkasan Transaksi
        </h2>

        <div>
          <Label for="customerSelect" class="mb-1">Pelanggan (Opsional)</Label>
          <Select v-model="selectedCustomerId">
            <SelectTrigger id="customerSelect">
              <SelectValue
                :placeholder="
                  selectedCustomerId === null
                    ? 'Pilih Pelanggan'
                    : customers.find((c) => c.id === selectedCustomerId)?.name
                "
              />
            </SelectTrigger>
            <SelectContent>
              <SelectItem :value="null">Tanpa Pelanggan</SelectItem>
              <template v-if="loadingCustomers">
                <div class="p-2 text-center text-gray-500 dark:text-gray-400">
                  Memuat pelanggan...
                </div>
              </template>
              <template v-else-if="customers.length === 0">
                <div class="p-2 text-center text-gray-500 dark:text-gray-400">
                  Tidak ada pelanggan ditemukan.
                </div>
              </template>
              <SelectItem
                v-for="customer in customers"
                :key="customer.id"
                :value="customer.id"
              >
                {{ customer.name }}
              </SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div class="space-y-2">
          <div class="flex justify-between">
            <span class="text-gray-700 dark:text-gray-300">Subtotal:</span>
            <span class="font-semibold text-gray-900 dark:text-white">{{
              formatCurrency(subtotal)
            }}</span>
          </div>
          <div>
            <Label for="discountAmount" class="mb-1">Diskon</Label>
            <Input
              id="discountAmount"
              v-model.number="discountAmount"
              type="number"
              step="0.01"
              min="0"
            />
          </div>
          <div>
            <Label for="taxAmount" class="mb-1">Pajak (%)</Label>
            <Input
              id="taxAmount"
              v-model.number="taxPercentage"
              type="number"
              step="0.01"
              min="0"
              max="100"
            />
          </div>
          <div class="flex justify-between font-bold text-xl border-t pt-2 mt-2">
            <span class="text-gray-900 dark:text-white">Total Akhir:</span>
            <span class="text-green-600 dark:text-green-400">{{
              formatCurrency(finalAmount)
            }}</span>
          </div>
        </div>

        <div>
          <Label for="paymentMethod" class="mb-1">Metode Pembayaran</Label>
          <Select v-model="paymentMethod">
            <SelectTrigger id="paymentMethod">
              <SelectValue :placeholder="paymentMethod" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="cash">Tunai</SelectItem>
              <SelectItem value="card">Kartu</SelectItem>
              <SelectItem value="digital_wallet">Dompet Digital</SelectItem>
              <SelectItem value="bank_transfer">Transfer Bank</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div>
          <Label for="paymentStatus" class="mb-1">Status Pembayaran</Label>
          <Select v-model="paymentStatus">
            <SelectTrigger id="paymentStatus">
              <SelectValue :placeholder="paymentStatus" />
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
          <Label for="notes" class="mb-1">Catatan</Label>
          <Textarea id="notes" v-model="notes" placeholder="Catatan transaksi..." />
        </div>

        <Button
          @click="processTransaction"
          class="w-full"
          :disabled="loadingTransaction || cartItems.length === 0"
        >
          <span v-if="loadingTransaction">Memproses Transaksi...</span>
          <span v-else>Selesaikan Transaksi</span>
        </Button>

        <div v-if="errorMessage" class="text-red-500 text-sm mt-4">
          {{ errorMessage }}
        </div>
        <div v-if="successMessage" class="text-green-500 text-sm mt-4">
          {{ successMessage }}
        </div>
      </div>

      <!-- Latest Transactions -->
      <div class="lg:col-span-3 bg-white dark:bg-gray-800 shadow-md rounded-lg p-6 mt-6">
        <h2 class="text-2xl font-semibold mb-4 text-gray-900 dark:text-white">
          Riwayat Transaksi Terbaru
        </h2>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>No. Transaksi</TableHead>
              <TableHead>Tanggal</TableHead>
              <TableHead>Pelanggan</TableHead>
              <TableHead>Total Akhir</TableHead>
              <TableHead>Status</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            <TableRow v-for="transaction in latestTransactions" :key="transaction.id">
              <TableCell>{{ transaction.transaction_number }}</TableCell>
              <TableCell>{{
                new Date(transaction.created_at).toLocaleString()
              }}</TableCell>
              <TableCell>{{ transaction.customers?.name || "Umum" }}</TableCell>
              <TableCell>{{ formatCurrency(transaction.final_amount) }}</TableCell>
              <TableCell>{{ transaction.payment_status }}</TableCell>
            </TableRow>
            <TableRow v-if="latestTransactions.length === 0">
              <TableCell colspan="5" class="text-center text-gray-500 dark:text-gray-400">
                Belum ada transaksi.
              </TableCell>
            </TableRow>
          </TableBody>
        </Table>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  title: 'Cashier - Aplikasi Kasir'
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

interface Product {
  id: string;
  name: string;
  description: string | null;
  price: number;
  cost: number | null;
  stock: number;
  is_active: boolean;
  image_url: string | null;
  sku: string | null; // Add sku to Product interface
  barcode: string | null; // Add barcode to Product interface
}

interface Customer {
  id: string;
  name: string;
  email: string | null;
  phone: string | null;
  address: string | null; // Added from customers.vue
  created_at: string; // Added from customers.vue
  updated_at: string; // Added from customers.vue
}

interface CartItem {
  product: Product;
  quantity: number;
  unit_price: number;
  total_price: number;
}

interface Transaction {
  id: string;
  transaction_number: string;
  created_at: string;
  total_amount: number;
  discount_amount: number;
  tax_amount: number;
  final_amount: number;
  payment_method: string;
  payment_status: string;
  notes: string | null;
  cashier_id: string;
  customer_id: string | null;
  customers?: { name: string } | null; // Joined customer name
}

const supabase = useSupabaseClient();
const user = useSupabaseUser();

const products = ref<Product[]>([]);
const customers = ref<Customer[]>([]);
const cartItems = ref<CartItem[]>([]);
const latestTransactions = ref<Transaction[]>([]);

const searchQuery = ref("");
const selectedCustomerId = ref<string | null>(null);
const discountAmount = ref(0);
const taxPercentage = ref(0);
const paymentMethod = ref("cash");
const paymentStatus = ref("completed");
const notes = ref("");

const pageLoading = ref(true); // New ref for overall page loading
const loadingProducts = ref(false);
const loadingCustomers = ref(false); // New loading state for customers
const loadingTransaction = ref(false);
const errorMessage = ref("");
const successMessage = ref("");
const hasCashierOrAdminRole = ref(false);

const fetchProducts = async () => {
  loadingProducts.value = true;
  errorMessage.value = "";
  try {
    const { data, error } = await supabase
      .from("products")
      .select("*")
      .eq("is_active", true)
      .gt("stock", 0) // Only show products with stock > 0
      .order("name", { ascending: true });

    if (error) throw error;
    products.value = data as Product[];
  } catch (error: any) {
    errorMessage.value = error.message;
  } finally {
    loadingProducts.value = false;
  }
};

const fetchCustomers = async () => {
  console.log("Fetching customers...");
  loadingCustomers.value = true;
  errorMessage.value = "";
  try {
    const { data, error } = await supabase
      .from("customers")
      .select("*")
      .order("name", { ascending: true });

    if (error) {
      console.error("Supabase error fetching customers:", error);
      throw error;
    }
    customers.value = data as Customer[];
    console.log("Customers fetched:", customers.value);
  } catch (error: any) {
    errorMessage.value = `Error fetching customers: ${error.message}`;
    console.error("Caught error fetching customers:", error.message);
  } finally {
    loadingCustomers.value = false;
    console.log("Finished fetching customers. Loading state:", loadingCustomers.value);
  }
};

const fetchLatestTransactions = async () => {
  errorMessage.value = "";
  try {
    const { data, error } = await supabase
      .from("transactions")
      .select("*, customers(name)")
      .order("created_at", { ascending: false })
      .limit(5); // Fetch latest 5 transactions

    if (error) throw error;
    latestTransactions.value = data as Transaction[];
  } catch (error: any) {
    errorMessage.value = `Error fetching latest transactions: ${error.message}`;
  }
};

const checkUserRole = async () => {
  if (!user.value) {
    hasCashierOrAdminRole.value = false;
    return;
  }
  const { data, error } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.value.id)
    .single();

  if (error) {
    console.error("Error fetching user role:", error.message);
    hasCashierOrAdminRole.value = false;
    return;
  }
  hasCashierOrAdminRole.value =
    data.role === "admin" || data.role === "manager" || data.role === "cashier";
  if (!hasCashierOrAdminRole.value) {
    errorMessage.value = "Anda tidak memiliki izin untuk mengakses halaman ini.";
  }
};

const filteredProducts = computed(() => {
  if (!searchQuery.value) {
    return products.value;
  }
  const query = searchQuery.value.toLowerCase();
  return products.value.filter(
    (product) =>
      product.name.toLowerCase().includes(query) ||
      product.description?.toLowerCase().includes(query) ||
      product.sku?.toLowerCase().includes(query) ||
      product.barcode?.toLowerCase().includes(query)
  );
});

const addProductToCart = (product: Product) => {
  const existingItemIndex = cartItems.value.findIndex(
    (item) => item.product.id === product.id
  );

  if (existingItemIndex > -1) {
    const existingItem = cartItems.value[existingItemIndex];
    if (existingItem.quantity < product.stock) {
      existingItem.quantity++;
      existingItem.total_price = existingItem.quantity * existingItem.unit_price;
    } else {
      alert(`Stok ${product.name} tidak mencukupi.`);
    }
  } else {
    if (product.stock > 0) {
      cartItems.value.push({
        product: product,
        quantity: 1,
        unit_price: product.price,
        total_price: product.price,
      });
    } else {
      alert(`Produk ${product.name} tidak memiliki stok.`);
    }
  }
};

const updateCartItemQuantity = (index: number, newQuantity: string) => {
  const quantity = parseInt(newQuantity);
  if (isNaN(quantity) || quantity <= 0) {
    cartItems.value[index].quantity = 1; // Reset to 1 if invalid
  } else if (quantity > cartItems.value[index].product.stock) {
    cartItems.value[index].quantity = cartItems.value[index].product.stock; // Cap at max stock
    alert(
      `Stok ${cartItems.value[index].product.name} tidak mencukupi. Maksimal ${cartItems.value[index].product.stock}.`
    );
  } else {
    cartItems.value[index].quantity = quantity;
  }
  cartItems.value[index].total_price =
    cartItems.value[index].quantity * cartItems.value[index].unit_price;
};

const removeProductFromCart = (index: number) => {
  cartItems.value.splice(index, 1);
};

const subtotal = computed(() => {
  return cartItems.value.reduce((sum, item) => sum + item.total_price, 0);
});

const totalDiscount = computed(() => {
  return Math.min(discountAmount.value, subtotal.value); // Discount cannot exceed subtotal
});

const totalTax = computed(() => {
  return (subtotal.value - totalDiscount.value) * (taxPercentage.value / 100);
});

const finalAmount = computed(() => {
  return subtotal.value - totalDiscount.value + totalTax.value;
});

const processTransaction = async () => {
  if (cartItems.value.length === 0) {
    errorMessage.value = "Keranjang belanja kosong.";
    return;
  }
  if (!user.value) {
    errorMessage.value = "Anda harus login untuk melakukan transaksi.";
    return;
  }

  loadingTransaction.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    // 1. Generate transaction number
    const {
      data: transactionNumberData,
      error: transactionNumberError,
    } = await supabase.rpc("generate_transaction_number");
    if (transactionNumberError) throw transactionNumberError;
    const transactionNumber = transactionNumberData;

    // 2. Insert transaction
    const { data: transactionData, error: transactionError } = await supabase
      .from("transactions")
      .insert({
        transaction_number: transactionNumber,
        cashier_id: user.value.id,
        customer_id: selectedCustomerId.value || null,
        total_amount: subtotal.value,
        discount_amount: totalDiscount.value,
        tax_amount: totalTax.value,
        final_amount: finalAmount.value,
        payment_method: paymentMethod.value,
        payment_status: paymentStatus.value,
        notes: notes.value,
      })
      .select("id")
      .single();

    if (transactionError) throw transactionError;
    const transactionId = transactionData.id;

    // 3. Insert transaction items and update product stock
    const transactionItemsToInsert = cartItems.value.map((item) => ({
      transaction_id: transactionId,
      product_id: item.product.id,
      quantity: item.quantity,
      unit_price: item.unit_price,
      total_price: item.total_price,
    }));

    const { error: itemsError } = await supabase
      .from("transaction_items")
      .insert(transactionItemsToInsert);

    if (itemsError) throw itemsError;

    // Update product stock
    for (const item of cartItems.value) {
      const { error: stockUpdateError } = await supabase
        .from("products")
        .update({ stock: item.product.stock - item.quantity })
        .eq("id", item.product.id);
      if (stockUpdateError) throw stockUpdateError;
    }

    successMessage.value = `Transaksi ${transactionNumber} berhasil diproses!`;
    resetTransaction();
    await fetchProducts(); // Refresh product list to reflect new stock
    await fetchLatestTransactions(); // Refresh latest transactions
  } catch (error: any) {
    errorMessage.value = error.message;
    console.error("Transaction error:", error);
  } finally {
    loadingTransaction.value = false;
  }
};

const resetTransaction = () => {
  cartItems.value = [];
  selectedCustomerId.value = null;
  discountAmount.value = 0;
  taxPercentage.value = 0;
  paymentMethod.value = "cash";
  paymentStatus.value = "completed";
  notes.value = "";
};

const formatCurrency = (value: number) => {
  return new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(value);
};

onMounted(async () => {
  pageLoading.value = true; // Start loading
  try {
    await checkUserRole();
    if (hasCashierOrAdminRole.value) {
      await fetchProducts();
      await fetchCustomers();
      await fetchLatestTransactions();
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
    if (hasCashierOrAdminRole.value) {
      await fetchProducts();
      await fetchCustomers();
      await fetchLatestTransactions();
    }
  } else {
    hasCashierOrAdminRole.value = false;
    products.value = [];
    customers.value = [];
    resetTransaction();
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
