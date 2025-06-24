<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-2 sm:p-4">
    <h1 class="text-3xl font-bold mb-6 text-gray-900 dark:text-white text-left">Kasir</h1>

    <div v-if="pageLoading" class="flex justify-center items-center h-64">
      <div class="spinner"></div>
    </div>

    <div
      v-else-if="!hasCashierOrAdminRole"
      class="text-center text-red-500 dark:text-red-400"
    >
      Anda tidak memiliki izin untuk mengakses halaman ini.
    </div>

    <div v-else class="flex flex-col gap-6">
      <!-- Product Selection -->
      <div>
        <Card class="mb-6">
          <CardHeader>
            <CardTitle>Pilih Produk</CardTitle>
          </CardHeader>
          <CardContent>
            <div class="flex flex-col sm:flex-row gap-4 mb-4">
              <Input
                v-model="searchQuery"
                placeholder="Cari produk..."
                class="w-full"
              />
              <Select v-model="selectedCategory" class="w-full sm:w-1/3">
                <SelectTrigger>
                  <SelectValue
                    :placeholder="
                      selectedCategory === null
                        ? 'Semua Kategori'
                        : categories.find((c) => c.id === selectedCategory)?.name ||
                          'Tidak Berkategori'
                    "
                  />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem :value="null">Semua Kategori</SelectItem>
                  <SelectItem
                    v-for="category in categories"
                    :key="category.id"
                    :value="category.id"
                  >
                    {{ category.name }}
                  </SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div
              v-if="loadingProducts"
              class="flex-shrink-0 w-full text-center text-gray-500 dark:text-gray-400"
            >
              Memuat produk...
            </div>
            <div
              v-else-if="Object.keys(groupedProductsByCategory).length === 0"
              class="flex-shrink-0 w-full text-center text-gray-500 dark:text-gray-400"
            >
              Tidak ada produk ditemukan.
            </div>
            <div v-else>
              <div
                v-for="(productsInGroup, categoryName) in groupedProductsByCategory"
                :key="categoryName"
                class="mb-6"
              >
                <h3 class="text-xl font-semibold mb-3 text-gray-800 dark:text-gray-200">
                  {{ categoryName }}
                </h3>
                <div class="flex overflow-x-auto pb-4 space-x-4">
                  <Card
                    v-for="product in productsInGroup"
                    :key="product.id"
                    class="flex-shrink-0 w-48 cursor-pointer flex-col overflow-hidden rounded-lg border bg-white shadow-sm transition-all hover:shadow-lg dark:border-gray-700 dark:bg-gray-800"
                    @click="addProductToCart(product)"
                  >
                    <div class="relative">
                      <img
                        v-if="product.image_url"
                        :src="product.image_url"
                        alt="Product Image"
                        class="aspect-square w-full object-cover -mt-6"
                      />
                      <div
                        v-else
                        class="flex aspect-square w-full items-center justify-center bg-gray-200 text-gray-500 dark:bg-gray-700 dark:text-gray-400"
                      >
                        No Image
                      </div>
                      <div class="absolute right-2 -top-4 flex items-center space-x-2">
                        <Badge
                          :class="{
                            'bg-green-500 text-white': product.stock > 10,
                            'bg-orange-500 text-white':
                              product.stock <= 10 && product.stock > 0,
                            'bg-red-500 text-white': product.stock === 0,
                          }"
                          class="text-xs"
                        >
                          {{
                            product.stock > 10
                              ? "Stok Aman"
                              : product.stock > 0
                              ? "Stok Rendah"
                              : "Stok Habis"
                          }}
                        </Badge>
                      </div>
                    </div>
                    <CardContent class="px-3">
                      <h3
                        class="mb-1 text-lg font-semibold text-gray-900 dark:text-white truncate"
                      >
                        {{ product.name }}
                      </h3>
                      <p class="text-xl font-bold text-green-600 dark:text-green-400">
                        {{ formatCurrency(product.price) }}
                      </p>
                      <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
                        Stok: {{ product.stock }}
                      </p>
                    </CardContent>
                  </Card>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
        <!-- Cart & Transaction Summary -->
        <div class="grid grid-cols-1 lg:grid-cols-5 gap-6 mb-6">
          <!-- Cart -->
          <Card class="lg:col-span-3">
            <CardHeader>
              <CardTitle>Keranjang Belanja</CardTitle>
            </CardHeader>
            <CardContent>
              <div class="flex justify-between items-center mb-4">
                <Button
                  variant="outline"
                  size="sm"
                  @click="resetTransaction"
                  :disabled="cartItems.length === 0"
                  class="text-red-500 border-red-500 hover:bg-red-50 dark:hover:bg-red-900"
                >
                  Bersihkan Keranjang
                </Button>
              </div>
              <div class="overflow-x-auto">
                <Table class="min-w-full">
                  <TableHeader>
                    <TableRow>
                      <TableHead class="min-w-[120px]">Produk</TableHead>
                      <TableHead class="w-[80px] text-center">Qty</TableHead>
                      <TableHead class="min-w-[100px]">Harga Satuan</TableHead>
                      <TableHead class="min-w-[100px]">Total</TableHead>
                      <TableHead class="w-[60px] text-center">Aksi</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    <TableRow v-for="(item, index) in cartItems" :key="item.product.id">
                      <TableCell class="font-medium">{{ item.product.name }}</TableCell>
                      <TableCell class="text-center">
                        <div class="flex items-center justify-center space-x-1">
                          <Button
                            variant="outline"
                            size="icon"
                            class="h-8 w-8 p-0"
                            @click="decrementQuantity(index)"
                            :disabled="item.quantity <= 1"
                          >
                            -
                          </Button>
                          <Input
                            type="number"
                            v-model.number="item.quantity"
                            min="1"
                            :max="item.product.stock"
                            @change="updateCartItemQuantity(index, $event.target.value)"
                            class="w-16 text-center"
                          />
                          <Button
                            variant="outline"
                            size="icon"
                            class="h-8 w-8 p-0"
                            @click="incrementQuantity(index)"
                            :disabled="item.quantity >= item.product.stock"
                          >
                            +
                          </Button>
                        </div>
                      </TableCell>
                      <TableCell>{{ formatCurrency(item.product.price) }}</TableCell>
                      <TableCell>{{ formatCurrency(item.total_price) }}</TableCell>
                      <TableCell class="text-center">
                        <Button
                          variant="destructive"
                          size="icon"
                          class="h-8 w-8"
                          @click="removeProductFromCart(index)"
                        >
                          <Trash2 class="h-4 w-4" />
                        </Button>
                      </TableCell>
                    </TableRow>
                    <TableRow v-if="cartItems.length === 0">
                      <TableCell
                        colspan="5"
                        class="text-center text-gray-500 dark:text-gray-400 py-4"
                      >
                        Keranjang kosong. Tambahkan produk untuk memulai transaksi.
                      </TableCell>
                    </TableRow>
                  </TableBody>
                </Table>
</div>


            </CardContent>
          </Card>

          <Card class="lg:col-span-2">
            <CardHeader>
              <CardTitle>Ringkasan & Pembayaran</CardTitle>
            </CardHeader>
            <CardContent class="space-y-4">
              <div>
                <Label for="customerSelect" class="mb-2">Pelanggan (Opsional)</Label>
                <Select v-model="selectedCustomerId">
                  <SelectTrigger id="customerSelect" class="w-full">
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

              <div class="space-y-3">
                <div class="flex justify-between items-center">
                  <span class="text-gray-700 dark:text-gray-300 text-lg">Subtotal:</span>
                  <span class="font-semibold text-gray-900 dark:text-white text-lg">{{
                    formatCurrency(subtotal)
                  }}</span>
                </div>
                <div>
                  <Label for="discountAmount" class="mb-1 text-sm">Diskon</Label>
                  <Input
                    id="discountAmount"
                    v-model.number="discountAmount"
                    type="number"
                    step="1000"
                    min="0"
                    placeholder="0"
                  />
                </div>
                <div>
                  <Label for="taxAmount" class="mb-1 text-sm">Pajak (%)</Label>
                  <Input
                    id="taxAmount"
                    v-model.number="taxPercentage"
                    type="number"
                    step="0.1"
                    min="0"
                    max="100"
                    placeholder="0"
                  />
                </div>
                <div class="flex justify-between font-bold text-2xl border-t pt-4 mt-4">
                  <span class="text-gray-900 dark:text-white">Total Akhir:</span>
                  <span class="text-green-600 dark:text-green-400">{{
                    formatCurrency(finalAmount)
                  }}</span>
                </div>
              </div>

              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <Label for="paymentMethod" class="mb-1 text-sm">Metode Pembayaran</Label>
                  <Select v-model="paymentMethod">
                    <SelectTrigger id="paymentMethod" class="w-full">
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
                  <Label for="paymentStatus" class="mb-1 text-sm">Status Pembayaran</Label>
                  <Select v-model="paymentStatus">
                    <SelectTrigger id="paymentStatus" class="w-full">
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
              </div>

              <div>
                <Label for="notes" class="mb-1 text-sm">Catatan</Label>
                <Textarea
                  id="notes"
                  v-model="notes"
                  placeholder="Tambahkan catatan transaksi..."
                />
              </div>

              <Button
                @click="processTransaction"
                class="w-full"
                :disabled="loadingTransaction || cartItems.length === 0"
              >
                <span v-if="loadingTransaction">Memproses Transaksi...</span>
                <span v-else>Selesaikan Transaksi</span>
              </Button>
            </CardContent>
          </Card>
        </div>

        <!-- Latest Transactions -->
        <Card>
          <CardHeader>
            <CardTitle>Riwayat Transaksi Terbaru</CardTitle>
          </CardHeader>
          <CardContent>
            <div class="overflow-x-auto">
              <Table class="min-w-full">
                <TableHeader>
                  <TableRow>
                    <TableHead class="min-w-[120px]">No. Transaksi</TableHead>
                    <TableHead class="min-w-[150px]">Tanggal</TableHead>
                    <TableHead class="min-w-[120px]">Pelanggan</TableHead>
                    <TableHead class="min-w-[120px]">Total Akhir</TableHead>
                    <TableHead class="min-w-[100px]">Status</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  <TableRow v-for="transaction in latestTransactions" :key="transaction.id">
                    <TableCell class="font-medium">{{
                      transaction.transaction_number
                    }}</TableCell>
                    <TableCell>{{
                      new Date(transaction.created_at).toLocaleString()
                    }}</TableCell>
                    <TableCell>{{ transaction.customers?.name || "Umum" }}</TableCell>
                    <TableCell>{{ formatCurrency(transaction.final_amount) }}</TableCell>
                    <TableCell>{{ transaction.payment_status }}</TableCell>
                  </TableRow>
                  <TableRow v-if="latestTransactions.length === 0">
                    <TableCell
                      colspan="5"
                      class="text-center text-gray-500 dark:text-gray-400 py-4"
                    >
                      Belum ada transaksi.
                    </TableCell>
                  </TableRow>
                </TableBody>
              </Table>
              </div>
            </CardContent>

          </Card>
      </div>
      <Toaster />
    </div>

    <!-- Cash Payment Dialog -->
    <!-- Cash Payment Input Dialog -->
    <Dialog :open="showCashDialog" @update:open="showCashDialog = $event">
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Pembayaran Tunai</DialogTitle>
          <DialogDescription>
            Masukkan jumlah uang tunai yang diterima dari pembeli.
          </DialogDescription>
        </DialogHeader>
        <div class="grid gap-4 py-4">
          <div class="grid grid-cols-4 items-center gap-4">
            <Label for="finalAmount" class="text-right"> Total </Label>
            <div id="finalAmount" class="col-span-3 text-right text-lg font-semibold">
              {{ formatCurrency(finalAmount) }}
            </div>
          </div>
          <div class="grid grid-cols-4 items-center gap-4">
            <Label for="cashReceived" class="text-right"> Uang Diterima </Label>
            <Input
              id="cashReceived"
              v-model.number="cashReceived"
              type="number"
              step="1000"
              min="0"
              class="col-span-3"
              @keyup.enter="handleCashInput"
            />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" @click="showCashDialog = false">Batal</Button>
          <Button @click="handleCashInput" :disabled="cashReceived < finalAmount">
            Lanjutkan
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

    <!-- Change Amount Dialog -->
    <Dialog :open="showChangeDialog" @update:open="showChangeDialog = $event">
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Detail Pembayaran Tunai</DialogTitle>
          <DialogDescription>
            Berikut adalah rincian pembayaran dan kembalian.
          </DialogDescription>
        </DialogHeader>
        <div class="grid gap-4 py-4">
          <div class="grid grid-cols-4 items-center gap-4">
            <Label for="changeAmountDisplay" class="text-right"> Kembalian </Label>
            <div id="finalAmount" class="col-span-3 text-right text-lg font-semibold">
              {{ formatCurrency(changeAmount) }}
            </div>
          </div>
        </div>
        <DialogFooter>
          <Button @click="finalizeTransaction" :disabled="loadingTransaction"
            >Selesai</Button
          >
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  title: "Cashier - Aplikasi Kasir",
});
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
import { toast } from "vue-sonner";
import { Toaster } from "@/components/ui/sonner";
import "vue-sonner/style.css";
import { Trash2 } from "lucide-vue-next";
import { Card, CardContent } from "@/components/ui/card"; // Import Card and CardContent
import { Badge } from "@/components/ui/badge"; // Import Badge
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";

interface Category {
  id: string;
  name: string;
  created_at: string;
  updated_at: string;
}

interface Product {
  id: string;
  name: string;
  description: string | null;
  price: number;
  cost: number | null;
  stock: number;
  is_active: boolean;
  image_url: string | null;
  sku: string | null;
  barcode: string | null;
  category_id: string | null; // Add category_id
  categories: { name: string } | null; // For joined category name
}

interface Customer {
  id: string;
  name: string;
  email: string | null;
  phone: string | null;
  address: string | null;
  created_at: string;
  updated_at: string;
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
const categories = ref<Category[]>([]); // New ref for categories
const customers = ref<Customer[]>([]);
const cartItems = ref<CartItem[]>([]);
const latestTransactions = ref<Transaction[]>([]);

const searchQuery = ref("");
const selectedCategory = ref<string | null>(null); // New ref for selected category
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
const hasCashierOrAdminRole = ref(false);
const showCashDialog = ref(false);
const showChangeDialog = ref(false); // New dialog state
const cashReceived = ref(0);
const changeAmount = ref(0);

const fetchProducts = async () => {
  loadingProducts.value = true;
  try {
    const { data, error } = await supabase
      .from("products")
      .select("*, categories(name)") // Select category name
      .eq("is_active", true)
      .gt("stock", 0) // Only show products with stock > 0
      .order("name", { ascending: true });

    if (error) throw error;
    products.value = data as Product[];
  } catch (error: any) {
    toast.error("Gagal memuat produk!", {
      description: error.message,
    });
  } finally {
    loadingProducts.value = false;
  }
};

const fetchCategories = async () => {
  try {
    const { data, error } = await supabase
      .from("categories")
      .select("*")
      .order("name", { ascending: true });

    if (error) throw error;
    categories.value = data as Category[];
  } catch (error: any) {
    toast.error("Gagal memuat kategori!", {
      description: error.message,
    });
  }
};

const fetchCustomers = async () => {
  loadingCustomers.value = true;
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
  } catch (error: any) {
    toast.error("Gagal memuat pelanggan!", {
      description: error.message,
    });
  } finally {
    loadingCustomers.value = false;
  }
};

const fetchLatestTransactions = async () => {
  try {
    const { data, error } = await supabase
      .from("transactions")
      .select("*, customers(name)")
      .order("created_at", { ascending: false })
      .limit(5); // Fetch latest 5 transactions

    if (error) throw error;
    latestTransactions.value = data as Transaction[];
  } catch (error: any) {
    toast.error("Gagal memuat riwayat transaksi!", {
      description: error.message,
    });
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
    toast.error("Gagal memeriksa peran pengguna!", {
      description: error.message,
    });
    hasCashierOrAdminRole.value = false;
    return;
  }
  hasCashierOrAdminRole.value =
    data.role === "admin" || data.role === "manager" || data.role === "cashier";
  if (!hasCashierOrAdminRole.value) {
    toast.warning("Akses Ditolak", {
      description: "Anda tidak memiliki izin untuk mengakses halaman ini.",
    });
  }
};

const filteredProducts = computed(() => {
  let filtered = products.value;

  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase();
    filtered = filtered.filter(
      (product) =>
        product.name.toLowerCase().includes(query) ||
        product.description?.toLowerCase().includes(query) ||
        product.sku?.toLowerCase().includes(query) ||
        product.barcode?.toLowerCase().includes(query)
    );
  }

  if (selectedCategory.value) {
    filtered = filtered.filter(
      (product) => product.category_id === selectedCategory.value
    );
  }

  return filtered;
});

const groupedProductsByCategory = computed(() => {
  const grouped: { [key: string]: Product[] } = {};
  filteredProducts.value.forEach((product) => {
    const categoryName = product.categories?.name || "Tidak Berkategori";
    if (!grouped[categoryName]) {
      grouped[categoryName] = [];
    }
    grouped[categoryName].push(product);
  });
  return grouped;
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

const incrementQuantity = (index: number) => {
  const item = cartItems.value[index];
  if (item.quantity < item.product.stock) {
    item.quantity++;
    item.total_price = item.quantity * item.unit_price;
  } else {
    toast.warning("Peringatan", {
      description: `Stok ${item.product.name} tidak mencukupi.`,
    });
  }
};

const decrementQuantity = (index: number) => {
  const item = cartItems.value[index];
  if (item.quantity > 1) {
    item.quantity--;
    item.total_price = item.quantity * item.unit_price;
  }
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
    toast.warning("Peringatan", {
      description: "Keranjang belanja kosong. Tambahkan produk terlebih dahulu.",
    });
    return;
  }
  if (!user.value) {
    toast.error("Error", {
      description: "Anda harus login untuk melakukan transaksi.",
    });
    return;
  }

  if (paymentMethod.value === "cash") {
    showCashDialog.value = true;
    cashReceived.value = 0; // Reset cash received for new input
    changeAmount.value = 0; // Reset change amount
    return; // Stop here, wait for cash input in the first dialog
  }

  if (paymentMethod.value === "non-cash") {
    paymentStatus.value = "completed"; // Set to completed for non-cash payments
  }
  await finalizeTransaction();
};

const finalizeTransaction = async () => {
  loadingTransaction.value = true;

  try {
    // 1. Generate transaction number
    const {
      data: transactionNumberData,
      error: transactionNumberError,
    } = await supabase.rpc("generate_transaction_number");
    if (transactionNumberError) throw transactionNumberError;
    const transactionNumber = transactionNumberData;

    // 2. Insert transaction
    const transactionPayload = {
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
    };
    console.log("Inserting transaction with payload:", transactionPayload);
    const { data: transactionData, error: transactionError } = await supabase
      .from("transactions")
      .insert(transactionPayload)
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

    console.log("Inserting transaction items:", transactionItemsToInsert);
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

    toast.success("Transaksi Berhasil", {
      description: `Transaksi ${transactionNumber} berhasil diproses!`,
    });
    resetTransaction();
    await fetchProducts(); // Refresh product list to reflect new stock
    await fetchLatestTransactions(); // Refresh latest transactions
  } catch (error: any) {
    toast.error("Error Transaksi", {
      description: `Gagal memproses transaksi: ${error.message}`,
    });
  } finally {
    loadingTransaction.value = false;
    showCashDialog.value = false; // Close cash input dialog
    showChangeDialog.value = false; // Close change display dialog
  }
};

const handleCashInput = () => {
  if (cashReceived.value < finalAmount.value) {
    toast.error("Pembayaran Kurang", {
      description: `Uang yang diberikan kurang. Dibutuhkan ${formatCurrency(
        finalAmount.value
      )}`,
    });
    return;
  }
  changeAmount.value = cashReceived.value - finalAmount.value;
  showCashDialog.value = false; // Close the cash input dialog
  showChangeDialog.value = true; // Open the change display dialog
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
      await fetchCategories(); // Fetch categories on mount
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
      await fetchCategories(); // Fetch categories on user change
      await fetchCustomers();
      await fetchLatestTransactions();
    }
  } else {
    hasCashierOrAdminRole.value = false;
    products.value = [];
    categories.value = []; // Clear categories
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
